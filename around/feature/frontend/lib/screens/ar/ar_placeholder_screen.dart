import 'package:flutter/material.dart';

class ArPlaceholderScreen extends StatelessWidget {
  const ArPlaceholderScreen({super.key});

  static const _base = Color(0xFF151E3F);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _base.withOpacity(0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.view_in_ar, color: _base, size: 38),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'AR Mode',
                    style: TextStyle(
                      color: _base,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This feature is under development. It will be available soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _base.withOpacity(0.72), height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  const Chip(
                    backgroundColor: Color(0xFFFFF3D9),
                    side: BorderSide.none,
                    label: Text(
                      'Temporarily unavailable',
                      style: TextStyle(color: _base, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can switch to other tabs below.',
                    style: TextStyle(color: _base),
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
