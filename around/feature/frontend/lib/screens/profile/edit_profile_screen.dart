import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final name = context.read<AuthState>().username;
    if (name != null) {
      _usernameCtrl.text = name;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _avatarPath = picked.path);
  }

  Future<void> _save() async {
    final auth = context.read<AuthState>();
    final ok = await auth.updateProfile(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim().isEmpty
          ? null
          : _passwordCtrl.text.trim(),
      avatarFilePath: _avatarPath,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
      return;
    }
    if (auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthState>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.auth, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final avatarUrl = auth.avatarUrl;
    final busy = auth.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _base.withOpacity(0.12)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14151E3F),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: busy ? null : _pickAvatar,
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFF8E8),
                          border: Border.all(
                            color: _accent.withOpacity(0.9),
                            width: 1.4,
                          ),
                        ),
                        child: ClipOval(
                          child: _avatarPath != null
                              ? Image.file(
                                  File(_avatarPath!),
                                  fit: BoxFit.cover,
                                )
                              : (avatarUrl != null
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.person_outline,
                                              size: 62,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.person_outline,
                                        size: 62,
                                        color: _base,
                                      )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to choose photo',
                      style: TextStyle(color: _base.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _usernameCtrl,
                      enabled: !busy,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      enabled: !busy,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        helperText:
                            'Leave empty if you do not want to change it',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: busy ? null : _save,
                        child: busy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: busy ? null : _logout,
                        child: const Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
