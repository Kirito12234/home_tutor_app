import 'package:hive/hive.dart';

class UserHiveModel {
  final String name;

  final String email;

  final String passwordHash;

  const UserHiveModel({
    required this.name,
    required this.email,
    required this.passwordHash,
  });
}

class UserHiveModelAdapter extends TypeAdapter<UserHiveModel> {
  @override
  final int typeId = 1;

  @override
  UserHiveModel read(BinaryReader reader) {
    final fields = reader.readByte();
    final values = <int, dynamic>{};
    for (var i = 0; i < fields; i++) {
      values[reader.readByte()] = reader.read();
    }
    return UserHiveModel(
      name: values[0] as String,
      email: values[1] as String,
      passwordHash: values[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.passwordHash);
  }
}
