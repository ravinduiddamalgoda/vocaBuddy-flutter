import 'package:flutter/material.dart';

import '../../models/app_user_profile.dart';
import '../../services/firebase_auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoggingOut = false;
  bool _isLoadingProfile = true;
  String? _profileLoadError;
  AppUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final cachedProfile = await _authService.getCachedUserProfile();
    if (!mounted) {
      return;
    }

    if (cachedProfile != null) {
      setState(() {
        _profile = cachedProfile;
        _isLoadingProfile = false;
      });
    }

    try {
      final latestProfile = await _authService.syncAndCacheUserProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = latestProfile;
        _isLoadingProfile = false;
        _profileLoadError = null;
      });
    } on AuthServiceException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
        _profileLoadError = _profile == null ? e.message : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
        _profileLoadError = _profile == null
            ? 'Unable to load profile at the moment.'
            : null;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();
      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFFDFDFD),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoadingProfile && profile == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileField(
                            label: 'Name',
                            value: profile?.name ?? 'Not available',
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            label: 'Role',
                            value: profile?.role ?? 'Not available',
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            label: 'Age',
                            value: profile?.age?.toString() ?? 'Not available',
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            label: 'Username',
                            value: profile?.username ?? 'Not available',
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            label: 'Email',
                            value: (profile?.email.isNotEmpty == true)
                                ? profile!.email
                                : 'Not available',
                          ),
                          const SizedBox(height: 14),
                          _ProfileField(
                            label: 'User ID',
                            value: profile?.uid ?? 'Not available',
                          ),
                          if (_profileLoadError != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _profileLoadError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A6E5A)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF5A4332),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
