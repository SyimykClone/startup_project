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
      password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
      avatarFilePath: _avatarPath,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Профиль обновлён")),
      );
      Navigator.pop(context);
      return;
    }
    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
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
      appBar: AppBar(title: const Text("Редактирование профиля")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: busy ? null : _pickAvatar,
                    child: Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black54),
                      ),
                      child: ClipOval(
                        child: _avatarPath != null
                            ? Image.file(File(_avatarPath!), fit: BoxFit.cover)
                            : (avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person_outline, size: 68),
                                  )
                                : const Icon(Icons.person_outline, size: 68)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Нажмите, чтобы выбрать фото"),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameCtrl,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: "Имя пользователя",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Новый пароль",
                      helperText: "Оставьте пустым, если не меняете",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: busy ? null : _save,
                      child: busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Редактировать"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: busy ? null : _logout,
                      child: const Text("Выход"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
