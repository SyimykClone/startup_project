import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';
import '../../utils/app_error_text.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);
  static const _surface = Color(0xFFF4F6FC);

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _initialUsername = '';
  String? _avatarPath;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool get _hasPasswordInput =>
      _currentPasswordCtrl.text.trim().isNotEmpty ||
      _passwordCtrl.text.trim().isNotEmpty ||
      _confirmPasswordCtrl.text.trim().isNotEmpty;

  bool get _hasChanges =>
      _usernameCtrl.text.trim() != _initialUsername ||
      _avatarPath != null ||
      _hasPasswordInput;

  @override
  void initState() {
    super.initState();
    final name = context.read<AuthState>().username;
    if (name != null &&
        name.trim().isNotEmpty &&
        name.trim().toLowerCase() != 'user') {
      _usernameCtrl.text = name.trim();
      _initialUsername = name.trim();
    }
    _usernameCtrl.addListener(_onFieldChanged);
    _currentPasswordCtrl.addListener(_onFieldChanged);
    _passwordCtrl.addListener(_onFieldChanged);
    _confirmPasswordCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

  String get _accountRoleLabel {
    final auth = context.read<AuthState>();
    if (auth.isBusiness) {
      return _isRu ? 'Бизнес-аккаунт' : 'Business account';
    }
    return _isRu ? 'Путешественник' : 'Traveler';
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    final approved = await _showAvatarPreview(picked.path);
    if (approved == true && mounted) {
      setState(() => _avatarPath = picked.path);
    }
  }

  Future<bool?> _showAvatarPreview(String path) {
    final l10n = context.l10n;
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.photoPreviewTitle,
                  style: const TextStyle(
                    color: _base,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ClipOval(
                  child: Image.file(
                    File(path),
                    width: 168,
                    height: 168,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.chooseAnotherPhoto),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.usePhoto),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isRu ? 'Выйти без сохранения?' : 'Discard changes?'),
        content: Text(
          _isRu
              ? 'Изменения в профиле не будут сохранены.'
              : 'Your profile changes will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_isRu ? 'Остаться' : 'Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isRu ? 'Выйти' : 'Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthState>();
    final newPassword = _passwordCtrl.text.trim().isEmpty
        ? null
        : _passwordCtrl.text.trim();
    final ok = await auth.updateProfile(
      username: _usernameCtrl.text.trim(),
      currentPassword: newPassword == null
          ? null
          : _currentPasswordCtrl.text.trim(),
      password: newPassword,
      avatarFilePath: _avatarPath,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileUpdated)));
      Navigator.pop(context);
      return;
    }
    if (auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(AppErrorText.fromMessage(context, auth.error!))),
      );
    }
  }

  Future<void> _logout() async {
    final discard = await _confirmDiscardChanges();
    if (!discard || !mounted) return;
    final auth = context.read<AuthState>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.auth, (_) => false);
  }

  String? _validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return _isRu ? 'Укажите имя пользователя' : 'Enter username';
    }
    if (text.length < 3) {
      return _isRu ? 'Минимум 3 символа' : 'At least 3 characters';
    }
    if (text.length > 20) {
      return _isRu ? 'Максимум 20 символов' : 'Up to 20 characters';
    }
    if (text.toLowerCase() == 'user') {
      return _isRu ? 'Выберите более личное имя' : 'Choose a more personal name';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(text)) {
      return _isRu
          ? 'Используйте буквы, цифры, ., _, -'
          : 'Use letters, numbers, ., _, -';
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (!_hasPasswordInput) return null;
    if ((value ?? '').trim().isEmpty) {
      return _isRu ? 'Введите текущий пароль' : 'Enter current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_hasPasswordInput) return null;
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return _isRu ? 'Введите новый пароль' : 'Enter new password';
    }
    if (text.length < 6) {
      return _isRu ? 'Минимум 6 символов' : 'At least 6 characters';
    }
    if (text == _currentPasswordCtrl.text.trim()) {
      return _isRu
          ? 'Новый пароль должен отличаться'
          : 'New password must be different';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_hasPasswordInput) return null;
    if ((value ?? '').trim() != _passwordCtrl.text.trim()) {
      return _isRu ? 'Пароли не совпадают' : 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthState>();
    final avatarUrl = auth.avatarUrl;
    final busy = auth.isLoading;

    return WillPopScope(
      onWillPop: _confirmDiscardChanges,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.editProfile)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _ProfileHero(
                        avatarPath: _avatarPath,
                        avatarUrl: avatarUrl,
                        username: _usernameCtrl.text.trim().isEmpty
                            ? l10n.username
                            : _usernameCtrl.text.trim(),
                        role: _accountRoleLabel,
                        busy: busy,
                        onAvatarTap: _pickAvatar,
                      ),
                      const SizedBox(height: 14),
                      _ProfileSection(
                        icon: Icons.badge_outlined,
                        title: _isRu ? 'Профиль' : 'Profile',
                        subtitle: _isRu
                            ? 'Имя и фотография аккаунта'
                            : 'Account name and photo',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameCtrl,
                              enabled: !busy,
                              decoration: InputDecoration(
                                labelText: l10n.username,
                                helperText: _isRu
                                    ? '3-20 символов: буквы, цифры, ., _, -'
                                    : '3-20 chars: letters, numbers, ., _, -',
                              ),
                              autofillHints: const [AutofillHints.username],
                              validator: _validateUsername,
                            ),
                            const SizedBox(height: 12),
                            _InfoTile(
                              icon: Icons.verified_user_outlined,
                              title: _isRu ? 'Тип аккаунта' : 'Account type',
                              value: _accountRoleLabel,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ProfileSection(
                        icon: Icons.lock_outline_rounded,
                        title: _isRu ? 'Безопасность' : 'Security',
                        subtitle: _isRu
                            ? 'Изменение пароля аккаунта'
                            : 'Account password update',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _currentPasswordCtrl,
                              enabled: !busy,
                              obscureText: !_showCurrentPassword,
                              decoration: InputDecoration(
                                labelText: _isRu
                                    ? 'Текущий пароль'
                                    : 'Current password',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _showCurrentPassword =
                                        !_showCurrentPassword,
                                  ),
                                  icon: Icon(
                                    _showCurrentPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: _validateCurrentPassword,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              enabled: !busy,
                              obscureText: !_showNewPassword,
                              decoration: InputDecoration(
                                labelText: l10n.newPassword,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _showNewPassword = !_showNewPassword,
                                  ),
                                  icon: Icon(
                                    _showNewPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: _validateNewPassword,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              enabled: !busy,
                              obscureText: !_showConfirmPassword,
                              decoration: InputDecoration(
                                labelText: _isRu
                                    ? 'Повторите пароль'
                                    : 'Repeat password',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _showConfirmPassword =
                                        !_showConfirmPassword,
                                  ),
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: _validateConfirmPassword,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: busy || !_hasChanges ? null : _save,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: const Color(0xFFE6EAF2),
                            disabledForegroundColor: _base.withOpacity(0.42),
                          ),
                          child: busy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.saveChanges),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : _logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.82),
                              width: 1.2,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.08),
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.logOut),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.avatarPath,
    required this.avatarUrl,
    required this.username,
    required this.role,
    required this.busy,
    required this.onAvatarTap,
  });

  final String? avatarPath;
  final String? avatarUrl;
  final String username;
  final String role;
  final bool busy;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26151E3F),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: busy ? null : onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: ClipOval(
                    child: avatarPath != null
                        ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                        : (avatarUrl != null
                              ? Image.network(
                                  avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_outline,
                                    size: 48,
                                    color: base,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  size: 48,
                                  color: base,
                                )),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: base, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: base,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white.withOpacity(0.16)),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF151E3F);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: base.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12151E3F),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _EditProfileScreenState._surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: base),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: base,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: base.withOpacity(0.56),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF151E3F);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: base.withOpacity(0.72)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: base.withOpacity(0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: base,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
