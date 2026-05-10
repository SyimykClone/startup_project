import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_client.dart';
import '../../models/gamification.dart';
import '../../core/router/app_router.dart';
import '../../models/poi.dart';
import '../../services/gamification_service.dart';
import '../../services/poi_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.refreshTick});

  final int refreshTick;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const accent = Color(0xFFFAA916);
  static const base = Color(0xFF151E3F);

  late PoiService _poiService;
  late GamificationService _gamificationService;
  bool _initialized = false;
  List<Poi> _visited = [];
  GamificationProgress? _progress;
  bool _loadingProgress = false;
  String? _progressError;
  bool _loadingVisited = false;
  String? _visitedError;

  String _fallbackUsername() =>
      Localizations.localeOf(context).languageCode == 'ru'
          ? 'Путешественник'
          : 'Traveler';

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

  String _roleLabel(AuthState auth) {
    if (auth.isBusiness) return _isRu ? 'Бизнес-профиль' : 'Business profile';
    return _isRu ? 'Обычный пользователь' : 'Regular user';
  }

  String _rankTitle(int level) {
    if (level >= 5) return _isRu ? 'Гид маршрутов' : 'Route guide';
    if (level >= 3) return _isRu ? 'Исследователь' : 'Explorer';
    if (level >= 2) return _isRu ? 'Путешественник' : 'Traveler';
    return _isRu ? 'Новичок' : 'Beginner';
  }

  String _xpProgressText(GamificationProgress p) {
    final next = p.nextLevelXp;
    if (next == null) return _isRu ? 'Максимальный уровень' : 'Max level';
    return '${p.xp - p.currentLevelXp} / ${next - p.currentLevelXp} XP';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final cfg = context.read<AppConfig>();
    final token = context.read<AuthState>().token;
    _poiService = PoiService(
      ApiClient(cfg.apiBaseUrl, token: token),
      useMock: cfg.useMock,
    );
    _gamificationService = GamificationService(
      ApiClient(cfg.apiBaseUrl, token: token),
    );

    _loadProgress();
    _loadVisited();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadProgress();
      _loadVisited();
    }
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loadingProgress = true;
      _progressError = null;
    });
    try {
      final data = await _gamificationService.fetchMe();
      if (!mounted) return;
      setState(() => _progress = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _progressError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  Future<void> _loadVisited() async {
    setState(() {
      _loadingVisited = true;
      _visitedError = null;
    });
    try {
      final data = await _poiService.fetchVisited();
      if (!mounted) return;
      setState(() => _visited = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _visitedError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingVisited = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final rawUsername = auth.username?.trim();
    final username =
        rawUsername == null || rawUsername.isEmpty || rawUsername.toLowerCase() == 'user'
            ? _fallbackUsername()
            : rawUsername;
    final avatarUrl = auth.avatarUrl;
    final localeState = context.watch<LocaleState>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadProgress(), _loadVisited()]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(
              context,
              username: username,
              avatarUrl: avatarUrl,
              auth: auth,
              localeState: localeState,
            ),
            const SizedBox(height: 14),
            _buildGamificationCard(context),
            const SizedBox(height: 14),
            _buildVisitedPreview(context),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String username,
    required String? avatarUrl,
    required AuthState auth,
    required LocaleState localeState,
  }) {
    final progress = _progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, Routes.editProfile),
                borderRadius: BorderRadius.circular(44),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF8E8),
                    border: Border.all(color: accent, width: 1.5),
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
                      : const Icon(Icons.person_outline, size: 34, color: base),
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      progress == null
                          ? _roleLabel(auth)
                          : '${_rankTitle(progress.level)} · ${_roleLabel(auth)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.language,
                onSelected: (value) {
                  context.read<LocaleState>().setLocale(Locale(value));
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'ru', child: Text(context.l10n.russian)),
                  PopupMenuItem(value: 'en', child: Text(context.l10n.english)),
                ],
                child: _ProfilePill(
                  label: localeState.locale.languageCode.toUpperCase(),
                  icon: Icons.language,
                  dark: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ProfilePill(
                label: progress == null
                    ? 'XP 0'
                    : '${_isRu ? 'Уровень' : 'Level'} ${progress.level}',
                icon: Icons.auto_awesome,
                dark: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfilePill(
                  label: progress == null
                      ? (_isRu ? 'Активность пока пустая' : 'No activity yet')
                      : _xpProgressText(progress),
                  icon: Icons.bolt,
                  dark: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitedPreview(BuildContext context) {
    final visibleItems = _visited.take(3).toList();

    return _ProfileSection(
      title: context.l10n.visitedTitle,
      trailing: IconButton(
        onPressed: _loadingVisited ? null : _loadVisited,
        icon: const Icon(Icons.refresh, color: base),
      ),
      child: Builder(
        builder: (context) {
          if (_loadingVisited) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (_visitedError != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                context.l10n.loadError(_visitedError!),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (_visited.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                context.l10n.visitedEmpty,
                style: const TextStyle(
                  color: base,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return Column(
            children: [
              ...visibleItems.map(_buildVisitedItem),
              if (_visited.length > visibleItems.length) ...[
                const SizedBox(height: 8),
                Text(
                  _isRu
                      ? 'Показаны последние ${visibleItems.length} из ${_visited.length}'
                      : 'Showing latest ${visibleItems.length} of ${_visited.length}',
                  style: TextStyle(
                    color: base.withOpacity(0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildVisitedItem(Poi poi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: base.withOpacity(0.1)),
        ),
        leading: const Icon(Icons.place_outlined, color: base),
        title: Text(
          poi.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: base, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          poi.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'details') {
              Navigator.pushNamed(context, Routes.poiDetail, arguments: poi);
            }
            if (value == 'map') {
              Navigator.pushNamed(
                context,
                Routes.map,
                arguments: AppShellArgs(initialIndex: 2, initialPoi: poi),
              );
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'details', child: Text(context.l10n.details)),
            PopupMenuItem(value: 'map', child: Text(context.l10n.openOnMap)),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationCard(BuildContext context) {
    if (_loadingProgress) {
      return _ProfileSection(
        title: context.l10n.gamificationTitle,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_progressError != null || _progress == null) {
      return _ProfileSection(
        title: context.l10n.gamificationTitle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(context.l10n.loadError(_progressError ?? 'empty response')),
        ),
      );
    }

    final p = _progress!;
    final progress = (p.xpProgressPercent / 100).clamp(0.0, 1.0);
    final unlocked = p.achievements.where((a) => a.unlocked).length;

    return _ProfileSection(
      title: context.l10n.gamificationTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _rankTitle(p.level),
                style: const TextStyle(
                  color: base,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${p.xp} XP',
                style: const TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF2F3F8),
              valueColor: const AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _xpProgressText(p),
            style: TextStyle(color: base.withOpacity(0.75), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: _isRu ? 'Маршруты' : 'Routes',
                  value: p.routesBuilt.toString(),
                  icon: Icons.route_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: _isRu ? 'Места' : 'Places',
                  value: p.newPlacesVisited.toString(),
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: _isRu ? 'Бейджи' : 'Badges',
                  value: '$unlocked/${p.achievements.length}',
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.achievementsTitle,
            style: const TextStyle(color: base, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.achievements.map(
              (a) => _AchievementChip(
                title: _achievementTitle(context, a.code, a.title),
                unlocked: a.unlocked,
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  String _achievementTitle(BuildContext context, String code, String fallback) {
    switch (code) {
      case 'first_route':
        return context.l10n.achievementFirstRoute;
      case 'five_routes':
        return context.l10n.achievementFiveRoutes;
      case 'first_new_place':
        return context.l10n.achievementFirstNewPlace;
      default:
        return fallback;
    }
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProfileScreenState.base.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileScreenState.base,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.label,
    required this.icon,
    this.dark = false,
  });

  final String label;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : _ProfileScreenState.base;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFFFFF3D9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 15),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ProfileScreenState.base, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _ProfileScreenState.base,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ProfileScreenState.base.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({
    required this.title,
    required this.unlocked,
  });

  final String title;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFFFFF3D9)
            : const Color(0xFFF2F3F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock_outline,
            color: unlocked
                ? _ProfileScreenState.accent
                : _ProfileScreenState.base.withOpacity(0.5),
            size: 15,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked
                    ? _ProfileScreenState.base
                    : _ProfileScreenState.base.withOpacity(0.62),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
