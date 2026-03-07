import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
  });

  final String uid;
  final String email;
  final String username;

  factory AppUser.fromFirebaseUser(User user) {
    final email = user.email ?? '';
    final displayName = user.displayName?.trim();
    final username = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : _usernameFromEmail(email, fallback: user.uid);

    return AppUser(uid: user.uid, email: email, username: username);
  }

  static String _usernameFromEmail(String email, {required String fallback}) {
    if (email.isEmpty) {
      return fallback;
    }

    final atIndex = email.indexOf('@');
    if (atIndex <= 0) {
      return email;
    }

    return email.substring(0, atIndex);
  }
}
