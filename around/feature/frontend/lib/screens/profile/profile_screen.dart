import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../state/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final username = auth.username ?? "user";
    final avatarUrl = auth.avatarUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    username,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, Routes.editProfile),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black54),
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
                        : const Icon(Icons.person_outline, size: 34),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              "Посещенные места",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black54),
                    ),
                    child: const Icon(Icons.place_outlined, size: 27),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Достижения",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black54),
                    ),
                    child: const Icon(Icons.workspace_premium_outlined, size: 24),
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
