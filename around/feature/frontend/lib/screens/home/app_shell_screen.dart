import 'package:flutter/material.dart';

import '../ar/ar_placeholder_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../tours/tours_screen.dart';
import 'map_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 2;
  int _favoritesRefreshTick = 0;
  int _profileRefreshTick = 0;
  int _toursRefreshTick = 0;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          FavoritesScreen(refreshTick: _favoritesRefreshTick),
          const ArPlaceholderScreen(),
          const MapScreen(),
          ToursScreen(refreshTick: _toursRefreshTick),
          ProfileScreen(refreshTick: _profileRefreshTick),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x25151E3F),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 64,
                backgroundColor: Colors.white,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected ? base : base.withOpacity(0.6),
                  );
                }),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 0),
                ),
                indicatorColor: accent.withOpacity(0.33),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (value) => setState(() {
                  _index = value;
                  if (value == 0) _favoritesRefreshTick++;
                  if (value == 3) _toursRefreshTick++;
                  if (value == 4) _profileRefreshTick++;
                }),
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
                    label: '',
                  ),
                  NavigationDestination(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.view_in_ar_outlined, size: 22),
                    ),
                    selectedIcon: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.view_in_ar, size: 24),
                    ),
                    label: '',
                  ),
                  NavigationDestination(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.map_outlined, size: 22),
                    ),
                    selectedIcon: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.map_rounded, size: 24),
                    ),
                    label: '',
                  ),
                  NavigationDestination(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.explore_outlined, size: 22),
                    ),
                    selectedIcon: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.explore, size: 24),
                    ),
                    label: '',
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
                    label: '',
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
