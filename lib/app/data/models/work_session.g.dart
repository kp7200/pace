// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkSessionAdapter extends TypeAdapter<WorkSession> {
  @override
  final typeId = 0;

  @override
  WorkSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkSession(
      date: fields[0] as DateTime,
      checkInTime: fields[1] as DateTime,
      checkOutTime: fields[2] as DateTime?,
      targetHours: (fields[3] as num).toInt(),
      totalWorkedDuration: fields[4] == null
          ? Duration.zero
          : fields[4] as Duration,
      totalBreakDuration: fields[5] == null
          ? Duration.zero
          : fields[5] as Duration,
      currentBreakStartTime: fields[6] as DateTime?,
      notes: fields[7] == null ? const [] : (fields[7] as List).cast<Note>(),
      updatedAt: fields[8] as DateTime?,
      isSynced: fields[9] == null ? false : fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.checkInTime)
      ..writeByte(2)
      ..write(obj.checkOutTime)
      ..writeByte(3)
      ..write(obj.targetHours)
      ..writeByte(4)
      ..write(obj.totalWorkedDuration)
      ..writeByte(5)
      ..write(obj.totalBreakDuration)
      ..writeByte(6)
      ..write(obj.currentBreakStartTime)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
