import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
import '../models/app_user_profile.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;

  static const String _usersCollection = 'users';
  static const String _profileCacheKey = 'current_user_profile';

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  AppUser? get currentUser {
    if (!isSupportedPlatform) {
      return null;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    return AppUser.fromFirebaseUser(user);
  }

  Future<AppUser> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    if (!isSupportedPlatform) {
      throw const AuthServiceException(
        'Firebase login is currently enabled for Android/iOS only.',
      );
    }

    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
      throw const AuthServiceException('Username and password are required.');
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedUsername,
        password: normalizedPassword,
      );

      final signedInUser = credential.user;
      if (signedInUser == null) {
        throw const AuthServiceException('Login failed. Please try again.');
      }

      return AppUser.fromFirebaseUser(signedInUser);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_firebaseAuthErrorMessage(e));
    }
  }

  Future<AppUserProfile> syncAndCacheUserProfile({AppUser? baseUser}) async {
    final authUser = baseUser ?? currentUser;
    if (authUser == null) {
      throw const AuthServiceException('No logged in user found.');
    }

    Map<String, dynamic>? firestoreData;
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(authUser.uid)
          .get();

      firestoreData = doc.data();
    } catch (_) {
      firestoreData = null;
    }

    final profile = AppUserProfile.fromSources(
      authUser: authUser,
      firestoreData: firestoreData,
    );

    try {
      await _cacheUserProfile(profile);
    } catch (_) {
      // Continue even if local cache write fails.
    }

    return profile;
  }

  Future<AppUserProfile?> getCachedUserProfile() async {
    if (!isSupportedPlatform) {
      return null;
    }

    final cachedText = await _secureStorage.read(key: _profileCacheKey);
    if (cachedText == null || cachedText.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(cachedText);
      if (decoded is! Map<String, dynamic>) {
        await clearCachedUserProfile();
        return null;
      }

      return AppUserProfile.fromJson(decoded);
    } catch (_) {
      await clearCachedUserProfile();
      return null;
    }
  }

  Future<void> clearCachedUserProfile() async {
    if (!isSupportedPlatform) {
      return;
    }

    await _secureStorage.delete(key: _profileCacheKey);
  }

  Future<void> _cacheUserProfile(AppUserProfile profile) async {
    if (!isSupportedPlatform) {
      return;
    }

    await _secureStorage.write(
      key: _profileCacheKey,
      value: jsonEncode(profile.toJson()),
    );
  }

  Future<void> signOut() async {
    if (!isSupportedPlatform) {
      return;
    }

    await clearCachedUserProfile();
    await _firebaseAuth.signOut();
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Please enter a valid username/email.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this username/email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return exception.message ?? 'Login failed. Please try again.';
    }
  }
}
