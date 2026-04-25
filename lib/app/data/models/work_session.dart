import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'note.dart';

part 'work_session.g.dart';

@HiveType(typeId: 0)
class WorkSession extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final DateTime checkInTime;

  @HiveField(2)
  final DateTime? checkOutTime;

  @HiveField(3)
  final int targetHours;

  @HiveField(4)
  final Duration totalWorkedDuration;

  @HiveField(5)
  final Duration totalBreakDuration;

  @HiveField(6)
  final DateTime? currentBreakStartTime;

  @HiveField(7)
  final List<Note> notes;

  Duration get actualWorkedDuration {
    final result = totalWorkedDuration - totalBreakDuration;
    return result.isNegative ? Duration.zero : result;
  }

  WorkSession({
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.targetHours,
    this.totalWorkedDuration = Duration.zero,
    this.totalBreakDuration = Duration.zero,
    this.currentBreakStartTime,
    this.notes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'targetHours': targetHours,
      'totalWorkedDuration': totalWorkedDuration.inSeconds,
      'totalBreakDuration': totalBreakDuration.inSeconds,
      'currentBreakStartTime': currentBreakStartTime?.toIso8601String(),
      'notes': notes.map((x) => x.toMap()).toList(),
    };
  }

  factory WorkSession.fromMap(Map<String, dynamic> map) {
    return WorkSession(
      date: DateTime.parse(map['date']),
      checkInTime: DateTime.parse(map['checkInTime']),
      checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime']) : null,
      targetHours: map['targetHours'] ?? 8,
      totalWorkedDuration: Duration(seconds: map['totalWorkedDuration'] ?? 0),
      totalBreakDuration: Duration(seconds: map['totalBreakDuration'] ?? 0),
      currentBreakStartTime: map['currentBreakStartTime'] != null ? DateTime.parse(map['currentBreakStartTime']) : null,
      notes: List<Note>.from(map['notes']?.map((x) => Note.fromMap(x)) ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkSession.fromJson(String source) => WorkSession.fromMap(json.decode(source));

  WorkSession copyWith({
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? targetHours,
    Duration? totalWorkedDuration,
    Duration? totalBreakDuration,
    DateTime? currentBreakStartTime,
    bool clearCurrentBreakStartTime = false,
    List<Note>? notes,
  }) {
    return WorkSession(
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      targetHours: targetHours ?? this.targetHours,
      totalWorkedDuration: totalWorkedDuration ?? this.totalWorkedDuration,
      totalBreakDuration: totalBreakDuration ?? this.totalBreakDuration,
      currentBreakStartTime: clearCurrentBreakStartTime ? null : (currentBreakStartTime ?? this.currentBreakStartTime),
      notes: notes ?? this.notes,
    );
  }
}
