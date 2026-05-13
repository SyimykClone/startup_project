import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../models/poi.dart';
import '../ar/ar_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../tours/tours_screen.dart';
import 'map_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({
    super.key,
    this.initialIndex = 2,
    this.initialPoi,
  });

  final int initialIndex;
  final Poi? initialPoi;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _index;
  int _favoritesRefreshTick = 0;
  int _profileRefreshTick = 0;
  int _toursRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFAA916);
    const base = Color(0xFF151E3F);
    const shellBlue = Color(0xFF071C36);
    const innerSurface = Color(0xFFF4F6FC);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: shellBlue,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: ColoredBox(
              color: innerSurface,
              child: IndexedStack(
                index: _index,
                children: [
                  FavoritesScreen(refreshTick: _favoritesRefreshTick),
                  const ArScreen(),
                  MapScreen(initialPoi: widget.initialPoi),
                  ToursScreen(refreshTick: _toursRefreshTick),
                  ProfileScreen(refreshTick: _profileRefreshTick),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 64,
                backgroundColor: shellBlue,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected ? accent : Colors.white.withOpacity(0.72),
                  );
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    color: selected ? accent : Colors.white.withOpacity(0.72),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  );
                }),
                indicatorColor: Colors.white.withOpacity(0.08),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                destinations: [
                  NavigationDestination(
                    icon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.favorite_border, size: 22),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.favorite, size: 24),
                    ),
                    label: l10n.tabFavorites,
                  ),
                  NavigationDestination(
                    icon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.view_in_ar_outlined, size: 22),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.view_in_ar, size: 24),
                    ),
                    label: l10n.tabAr,
                  ),
                  NavigationDestination(
                    icon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.map_outlined, size: 22),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.map_rounded, size: 24),
                    ),
                    label: l10n.tabMap,
                  ),
                  NavigationDestination(
                    icon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.explore_outlined, size: 22),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.explore, size: 24),
                    ),
                    label: l10n.tabTours,
                  ),
                  NavigationDestination(
                    icon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.person_outline, size: 22),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.person, size: 24),
                    ),
                    label: l10n.tabProfile,
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
