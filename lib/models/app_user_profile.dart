import 'app_user.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.name,
    required this.role,
    this.age,
  });

  final String uid;
  final String email;
  final String username;
  final String name;
  final String role;
  final int? age;

  factory AppUserProfile.fromSources({
    required AppUser authUser,
    Map<String, dynamic>? firestoreData,
  }) {
    final data = firestoreData ?? const <String, dynamic>{};
    final name = _readString(data['name']) ?? authUser.username;
    final role = _readString(data['role']) ?? 'Not specified';
    final age = _readInt(data['age']);

    return AppUserProfile(
      uid: authUser.uid,
      email: authUser.email,
      username: authUser.username,
      name: name,
      role: role,
      age: age,
    );
  }

  factory AppUserProfile.fromJson(Map<String, dynamic> json) {
    return AppUserProfile(
      uid: _readString(json['uid']) ?? '',
      email: _readString(json['email']) ?? '',
      username: _readString(json['username']) ?? '',
      name: _readString(json['name']) ?? '',
      role: _readString(json['role']) ?? 'Not specified',
      age: _readInt(json['age']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'name': name,
      'role': role,
      'age': age,
    };
  }

  static String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static int? _readInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }
}
