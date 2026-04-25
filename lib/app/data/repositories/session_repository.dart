import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/storage_service.dart';
import '../models/work_session.dart';
import '../models/note.dart';

class SessionRepository {
  // Reads directly from HiveService box — no StorageService for sessions
  Box<WorkSession> get _box => HiveService.to.sessions;

  // ─── Key helpers ──────────────────────────────────────────────────────────
  String _dateKey(DateTime date) => DateFormat('yyyy_MM_dd').format(date);

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> saveSession(WorkSession session) async {
    await _box.put(_dateKey(session.date), session);
  }

  WorkSession? getSession(DateTime date) {
    return _box.get(_dateKey(date));
  }

  /// Returns Mon–Fri sessions for the week starting at [weekStart] (must be a Monday).
  /// Returns null for days with no session stored.
  Map<DateTime, WorkSession?> getSessionsForWeek(DateTime weekStart) {
    final result = <DateTime, WorkSession?>{};
    for (int i = 0; i < 5; i++) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      result[day] = getSession(day);
    }
    return result;
  }

  Future<void> clearSession(DateTime date) async {
    await _box.delete(_dateKey(date));
  }

  Future<void> clearAllHistory() async {
    await _box.clear();
  }

  /// All sessions ordered newest first.
  List<WorkSession> getAllSessions() {
    final sessions = _box.values.toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  // ─── One-time migration from SharedPreferences JSON ───────────────────────
  /// Call once on startup. Reads old JSON blobs from SharedPreferences,
  /// writes them into Hive, then removes the old keys.
  /// Safe to call on every launch — skips if migration is already done.
  Future<void> migrateFromSharedPrefs() async {
    final storage = StorageService.to;

    // Guard: if already migrated, skip
    final alreadyMigrated = storage.getBool('_hive_migration_done') ?? false;
    if (alreadyMigrated) return;

    final keys = storage.getKeys().toList();

    for (final key in keys) {
      if (!key.startsWith('session_')) continue;

      final json = storage.getString(key);
      if (json == null) continue;

      try {
        final session = WorkSession.fromJson(json);
        final hiveKey = _dateKey(session.date);
        if (_box.get(hiveKey) == null) {
          await _box.put(hiveKey, session);
        }
        await storage.remove(key);
      } catch (_) {
        // Bad data — skip silently, don't crash on legacy corruption
      }
    }

    // Mark migration done
    await storage.setBool('_hive_migration_done', true);
  }

  // ─── Dev helpers ──────────────────────────────────────────────────────────

  /// Injects mock data if the database only has 0 or 1 sessions (dev only).
  Future<void> injectMockDataIfNeeded() async {
    final existing = getAllSessions();
    if (existing.length > 1) return;

    final now = DateTime.now();
    for (int i = 1; i <= 3; i++) {
      final pastDate = DateTime(now.year, now.month, now.day - i);
      final checkIn = pastDate.add(Duration(hours: 9, minutes: i * 5));
      final checkOut = checkIn.add(Duration(hours: 8, minutes: 30 + (i * 10)));

      final mockSession = WorkSession(
        date: pastDate,
        checkInTime: checkIn,
        checkOutTime: checkOut,
        targetHours: 8,
        totalWorkedDuration: checkOut.difference(checkIn) - const Duration(hours: 1),
        totalBreakDuration: const Duration(hours: 1),
        notes: [
          Note(
            id: 'mock_${i}_1',
            timestamp: checkIn.add(const Duration(hours: 2)),
            content: 'Finished the daily standup, started working on feature $i.',
          ),
          Note(
            id: 'mock_${i}_2',
            timestamp: checkIn.add(const Duration(hours: 6)),
            content: 'Pushed changes to staging. Waiting for review.',
          ),
        ],
      );

      await saveSession(mockSession);
    }
  }
}
