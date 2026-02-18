import 'package:flutter/material.dart';

import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import 'map_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 1;

  static const _tabs = [
    FavoritesScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 62,
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 0),
              ),
              indicatorColor: const Color(0xFFE8DDF5),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.favorite_border, size: 22),
                  ),
                  selectedIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.favorite, size: 24),
                  ),
                  label: "",
                ),
                NavigationDestination(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.photo_camera_outlined, size: 22),
                  ),
                  selectedIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.photo_camera, size: 24),
                  ),
                  label: "",
                ),
                NavigationDestination(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.person_outline, size: 22),
                  ),
                  selectedIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.person, size: 24),
                  ),
                  label: "",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
