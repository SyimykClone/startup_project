import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);

    final auth = context.watch<AuthState>();
    final username = auth.username ?? 'user';
    final avatarUrl = auth.avatarUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: base.withOpacity(0.1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14151E3F),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      username,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: base,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.editProfile),
                    borderRadius: BorderRadius.circular(44),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF8E8),
                        border: Border.all(
                          color: accent.withOpacity(0.8),
                          width: 1.4,
                        ),
                      ),
                      child: avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person_outline, size: 34),
                              ),
                            )
                          : const Icon(
                              Icons.person_outline,
                              size: 34,
                              color: base,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Посещенные места',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: base,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, __) {
                  return _CircleItem(
                    icon: Icons.place_outlined,
                    iconColor: base,
                    borderColor: base.withOpacity(0.2),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Достижения',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: base,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, __) {
                  return _CircleItem(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: accent,
                    borderColor: accent.withOpacity(0.45),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleItem extends StatelessWidget {
  const _CircleItem({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14151E3F),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }
}
