import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'storage_service.dart';
import '../../data/models/work_session.dart';
import '../../data/models/note.dart';
import '../../data/repositories/session_repository.dart';

enum SyncStatus { online, syncing, offline, error }

class SyncService extends GetxService {
  static SyncService get to => Get.find();

  final _supabase = Supabase.instance.client;
  final _sessionRepo = Get.find<SessionRepository>();
  final _storage = StorageService.to;

  final Rx<SyncStatus> status = SyncStatus.offline.obs;
  final RxBool isCloudSyncEnabled = false.obs;

  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  Future<SyncService> init() async {
    isCloudSyncEnabled.value = _storage.getBool('cloud_sync_enabled') ?? true;
    
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        if (status.value == SyncStatus.offline) {
          status.value = SyncStatus.online;
          sync();
        }
      } else {
        status.value = SyncStatus.offline;
      }
    });

    // Initial check
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (result != ConnectivityResult.none) {
      status.value = SyncStatus.online;
      sync();
    }

    return this;
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  void toggleSync(bool enable) {
    isCloudSyncEnabled.value = enable;
    _storage.setBool('cloud_sync_enabled', enable);
    if (enable) sync();
  }

  String get lastSyncedDisplay {
    final ms = _storage.getInt('last_synced_at');
    if (ms == null) return 'Never';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('MMM d, h:mm a').format(date);
  }

  void syncNow() {
    sync();
  }

  void triggerSync() {
    if (isCloudSyncEnabled.value && status.value != SyncStatus.offline) {
      sync();
    }
  }

  Future<void> sync() async {
    if (!isCloudSyncEnabled.value) return;
    if (_isSyncing) return;
    if (status.value == SyncStatus.offline) return;
    
    final user = AuthService.to.currentUser.value;
    if (user == null) return;

    _isSyncing = true;
    status.value = SyncStatus.syncing;

    try {
      // 1. PULL from Supabase
      final lastSyncedAt = _storage.getString('last_synced_at');
      var query = _supabase.from('work_sessions').select().eq('user_id', user.id);
      
      if (lastSyncedAt != null) {
        query = query.gt('updated_at', lastSyncedAt);
      }

      final response = await query;

      final remoteSessions = (response as List).map((e) => _fromSupabaseMap(e)).toList();

      for (final remote in remoteSessions) {
        final local = _sessionRepo.getSession(remote.date);
        
        if (local == null) {
          // Exists on remote, not local -> Save local
          await _sessionRepo.saveSession(remote.copyWith(isSynced: true), isSyncUpdate: true);
        } else {
          // Compare updatedAt
          final localUpdated = local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final remoteUpdated = remote.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (remoteUpdated.isAfter(localUpdated)) {
            // Remote is newer: SMART MERGE
            // Merge notes so offline local notes aren't lost
            final mergedNotesMap = <String, Note>{};
            // Add all remote notes first
            for (final n in remote.notes) {
              mergedNotesMap[n.id] = n;
            }
            // Add any local notes that are missing
            for (final n in local.notes) {
              mergedNotesMap.putIfAbsent(n.id, () => n);
            }
            
            final mergedRemote = remote.copyWith(
              notes: mergedNotesMap.values.toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp)), // newest first
              isSynced: true,
            );
            await _sessionRepo.saveSession(mergedRemote, isSyncUpdate: true);
          }
        }
      }

      // 2. PUSH to Supabase
      final unsynced = _sessionRepo.getUnsyncedSessions();
      
      for (final session in unsynced) {
        final map = _toSupabaseMap(session, user.id);
        await _supabase.from('work_sessions').upsert(map);
        // Mark as synced locally
        await _sessionRepo.saveSession(session.copyWith(isSynced: true), isSyncUpdate: true);
      }

      // Update last synced time
      _storage.setString('last_synced_at', DateTime.now().toUtc().toIso8601String());

      status.value = SyncStatus.online;
    } catch (e) {
      print('Sync Error: $e');
      status.value = SyncStatus.error;
    } finally {
      _isSyncing = false;
    }
  }

  Map<String, dynamic> _toSupabaseMap(WorkSession session, String userId) {
    final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
    return {
      'id': '${userId}_$dateStr', // stable ID per user per day
      'user_id': userId,
      'date': session.date.toIso8601String(),
      'check_in_time': session.checkInTime.toIso8601String(),
      'check_out_time': session.checkOutTime?.toIso8601String(),
      'target_hours': session.targetHours,
      'total_worked_duration': session.totalWorkedDuration.inSeconds,
      'total_break_duration': session.totalBreakDuration.inSeconds,
      'current_break_start_time': session.currentBreakStartTime?.toIso8601String(),
      'notes': session.notes.map((n) => n.toMap()).toList(),
      'updated_at': (session.updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  WorkSession _fromSupabaseMap(Map<String, dynamic> map) {
    return WorkSession(
      date: DateTime.parse(map['date']),
      checkInTime: DateTime.parse(map['check_in_time']),
      checkOutTime: map['check_out_time'] != null ? DateTime.parse(map['check_out_time']) : null,
      targetHours: map['target_hours'] ?? 8,
      totalWorkedDuration: Duration(seconds: map['total_worked_duration'] ?? 0),
      totalBreakDuration: Duration(seconds: map['total_break_duration'] ?? 0),
      currentBreakStartTime: map['current_break_start_time'] != null ? DateTime.parse(map['current_break_start_time']) : null,
      notes: (map['notes'] as List?)?.map((n) => Note.fromMap(Map<String, dynamic>.from(n as Map))).toList() ?? [],
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      isSynced: true, // pulled from remote means it's synced
    );
  }
}
