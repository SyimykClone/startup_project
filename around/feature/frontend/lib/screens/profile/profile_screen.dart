import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../models/gamification.dart';
import '../../models/poi.dart';
import '../../models/route_models.dart';
import '../../services/gamification_service.dart';
import '../../services/poi_service.dart';
import '../../services/route_service.dart';
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
  static const soft = Color(0xFFF6F7FB);

  late PoiService _poiService;
  late GamificationService _gamificationService;
  late RouteService _routeService;
  bool _initialized = false;

  List<Poi> _visited = [];
  List<RouteHistoryItem> _routeHistory = [];
  GamificationProgress? _progress;

  bool _loadingProgress = false;
  bool _loadingVisited = false;
  bool _loadingRoutes = false;
  String? _progressError;
  String? _visitedError;
  String? _routesError;

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

  String _fallbackUsername() => _isRu ? 'Путешественник' : 'Traveler';

  String _rankTitle(int level) {
    if (level >= 10) return _isRu ? 'Мастер маршрутов' : 'Route master';
    if (level >= 8) return _isRu ? 'Гид маршрутов' : 'Route guide';
    if (level >= 5) return _isRu ? 'Следопыт' : 'Pathfinder';
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
    final api = ApiClient(cfg.apiBaseUrl, token: token);

    _poiService = PoiService(api, useMock: cfg.useMock);
    _gamificationService = GamificationService(api);
    _routeService = RouteService(api, useMock: cfg.useMock);

    _refreshProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    await Future.wait([
      _loadProgress(),
      _loadVisited(),
      _loadRouteHistory(),
    ]);
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

  Future<void> _loadRouteHistory() async {
    setState(() {
      _loadingRoutes = true;
      _routesError = null;
    });
    try {
      final data = await _routeService.fetchHistory(limit: 5);
      if (!mounted) return;
      setState(() => _routeHistory = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _routesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRoutes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final localeState = context.watch<LocaleState>();
    final rawUsername = auth.username?.trim();
    final username =
        rawUsername == null || rawUsername.isEmpty || rawUsername.toLowerCase() == 'user'
            ? _fallbackUsername()
            : rawUsername;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildHero(username, auth, localeState),
            const SizedBox(height: 14),
            _buildProgressSection(),
            const SizedBox(height: 14),
            _buildRouteHistorySection(),
            const SizedBox(height: 14),
            _buildVisitedSection(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String username, AuthState auth, LocaleState localeState) {
    final progress = _progress;
    final avatarUrl = auth.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(26),
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
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF8E8),
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person_outline, size: 36, color: base),
                          ),
                        )
                      : const Icon(Icons.person_outline, size: 36, color: base),
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
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      progress == null
                          ? (_isRu ? 'Профиль путешественника' : 'Traveler profile')
                          : _rankTitle(progress.level),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w700,
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
                  icon: Icons.language,
                  label: localeState.locale.languageCode.toUpperCase(),
                  dark: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.route_outlined,
                  value: progress?.routesBuilt.toString() ?? '0',
                  label: _isRu ? 'Маршруты' : 'Routes',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  icon: Icons.place_outlined,
                  value: progress?.newPlacesVisited.toString() ?? '0',
                  label: _isRu ? 'Места' : 'Places',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  icon: Icons.auto_awesome,
                  value: progress == null ? '0' : '${progress.level}',
                  label: _isRu ? 'Уровень' : 'Level',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_loadingProgress) {
      return const _ProfileSection(
        title: 'Прогресс',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_progressError != null || _progress == null) {
      return _ProfileSection(
        title: context.l10n.gamificationTitle,
        child: _ProfileEmptyState(
          icon: Icons.bolt_outlined,
          title: _isRu ? 'Прогресс недоступен' : 'Progress unavailable',
          text: context.l10n.loadError(_progressError ?? 'empty response'),
          actionLabel: _isRu ? 'Обновить' : 'Refresh',
          onAction: _loadProgress,
        ),
      );
    }

    final p = _progress!;
    final percent = (p.xpProgressPercent / 100).clamp(0.0, 1.0);
    final unlocked = p.achievements.where((a) => a.unlocked).length;
    final unlockedAchievements = p.achievements.where((a) => a.unlocked).toList();
    final lockedAchievements = p.achievements.where((a) => !a.unlocked).toList();

    return _ProfileSection(
      title: context.l10n.gamificationTitle,
      trailing: _ProfilePill(
        icon: Icons.emoji_events_outlined,
        label: '$unlocked/${p.achievements.length}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GameProgressCard(
            level: p.level,
            xp: p.xp,
            progress: percent,
            rankTitle: _rankTitle(p.level),
            progressText: _xpProgressText(p),
            unlockedCount: unlocked,
            totalCount: p.achievements.length,
          ),
          const SizedBox(height: 14),
          Text(
            _isRu ? 'Открытые достижения' : 'Unlocked achievements',
            style: const TextStyle(
              color: base,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unlockedAchievements
                .map(
                  (a) => _AchievementChip(
                    title: _achievementTitle(context, a.code, a.title),
                    unlocked: a.unlocked,
                  ),
                )
                .toList(),
          ),
          if (lockedAchievements.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _isRu ? 'Следующие цели' : 'Next goals',
              style: TextStyle(
                color: base.withOpacity(0.72),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lockedAchievements
                  .take(10)
                  .map(
                    (a) => _AchievementChip(
                      title: _achievementTitle(context, a.code, a.title),
                      unlocked: a.unlocked,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteHistorySection() {
    return _ProfileSection(
      title: _isRu ? 'История маршрутов' : 'Route history',
      trailing: IconButton(
        onPressed: _loadingRoutes ? null : _loadRouteHistory,
        icon: const Icon(Icons.refresh, color: base),
      ),
      child: Builder(
        builder: (_) {
          if (_loadingRoutes) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_routesError != null) {
            return _ProfileEmptyState(
              icon: Icons.route_outlined,
              title: _isRu ? 'История недоступна' : 'History unavailable',
              text: context.l10n.loadError(_routesError!),
              actionLabel: _isRu ? 'Обновить' : 'Refresh',
              onAction: _loadRouteHistory,
            );
          }
          if (_routeHistory.isEmpty) {
            return _ProfileEmptyState(
              icon: Icons.route_outlined,
              title: _isRu ? 'Маршрутов пока нет' : 'No routes yet',
              text: _isRu
                  ? 'Постройте маршрут на карте, и последние поездки появятся здесь.'
                  : 'Build a route on the map, and recent trips will appear here.',
            );
          }
          return Column(
            children: _routeHistory
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RouteHistoryTile(item: item),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildVisitedSection() {
    final visibleItems = _visited.take(4).toList();
    return _ProfileSection(
      title: context.l10n.visitedTitle,
      trailing: IconButton(
        onPressed: _loadingVisited ? null : _loadVisited,
        icon: const Icon(Icons.refresh, color: base),
      ),
      child: Builder(
        builder: (_) {
          if (_loadingVisited) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_visitedError != null) {
            return _ProfileEmptyState(
              icon: Icons.place_outlined,
              title: _isRu ? 'Посещённые места недоступны' : 'Visited unavailable',
              text: context.l10n.loadError(_visitedError!),
              actionLabel: _isRu ? 'Обновить' : 'Refresh',
              onAction: _loadVisited,
            );
          }
          if (_visited.isEmpty) {
            return _ProfileEmptyState(
              icon: Icons.place_outlined,
              title: context.l10n.visitedEmpty,
              text: _isRu
                  ? 'Сканируйте AR-объекты или отмечайте места на карте, чтобы собрать историю.'
                  : 'Scan AR objects or mark places on the map to build your history.',
            );
          }
          return Column(
            children: [
              ...visibleItems.map(
                (poi) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _VisitedTile(poi: poi),
                ),
              ),
              if (_visited.length > visibleItems.length)
                Text(
                  _isRu
                      ? 'Показаны последние ${visibleItems.length} из ${_visited.length}'
                      : 'Showing latest ${visibleItems.length} of ${_visited.length}',
                  style: TextStyle(
                    color: base.withOpacity(0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _achievementTitle(BuildContext context, String code, String fallback) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    switch (code) {
      case 'app_started':
        return isRu ? 'Первый запуск' : 'First launch';
      case 'profile_customized':
        return isRu ? 'Профиль оформлен' : 'Profile customized';
      case 'map_started':
        return isRu ? 'Карта освоена' : 'Map started';
      case 'favorite_started':
        return isRu ? 'Первое сохранение' : 'First save';
      case 'ar_object_found':
        return isRu ? 'AR-объект найден' : 'AR object found';
      case 'custom_point_created':
        return isRu ? 'Своя точка создана' : 'Custom point created';
      case 'all_rounder':
        return isRu ? 'Исследователь ARound' : 'ARound explorer';
      case 'first_route':
        return context.l10n.achievementFirstRoute;
      case 'five_routes':
        return context.l10n.achievementFiveRoutes;
      case 'ten_routes':
        return isRu ? '10 маршрутов' : '10 routes';
      case 'twenty_five_routes':
        return isRu ? '25 маршрутов' : '25 routes';
      case 'fifty_routes':
        return isRu ? '50 маршрутов' : '50 routes';
      case 'first_new_place':
        return context.l10n.achievementFirstNewPlace;
      case 'three_new_places':
        return isRu ? '3 новых места' : '3 new places';
      case 'ten_new_places':
        return isRu ? '10 новых мест' : '10 new places';
      case 'twenty_five_new_places':
        return isRu ? '25 новых мест' : '25 new places';
      case 'xp_500':
        return isRu ? '500 XP опыта' : '500 XP earned';
      case 'xp_100':
        return isRu ? '100 XP опыта' : '100 XP earned';
      case 'xp_750':
        return isRu ? '750 XP опыта' : '750 XP earned';
      case 'xp_1500':
        return isRu ? '1500 XP опыта' : '1500 XP earned';
      case 'xp_2500':
        return isRu ? '2500 XP опыта' : '2500 XP earned';
      case 'xp_3500':
        return isRu ? '3500 XP опыта' : '3500 XP earned';
      case 'profile_opened':
        return isRu ? 'Профиль исследован' : 'Profile explored';
      case 'business_profile_opened':
        return isRu ? 'Бизнес-профиль настроен' : 'Business profile explored';
      case 'first_favorite':
        return isRu ? 'Первое избранное' : 'First favorite';
      case 'five_favorites':
        return isRu ? '5 мест в избранном' : '5 favorites';
      case 'ten_favorites':
        return isRu ? '10 мест в избранном' : '10 favorites';
      case 'first_custom_point':
        return isRu ? 'Своя точка на карте' : 'Custom map point';
      case 'three_custom_points':
        return isRu ? '3 свои точки' : '3 custom points';
      case 'first_tour_created':
        return isRu ? 'Первый тур создан' : 'First tour created';
      case 'three_tours_created':
        return isRu ? '3 тура создано' : '3 tours created';
      case 'five_tours_created':
        return isRu ? '5 туров создано' : '5 tours created';
      case 'first_draft_tour':
        return isRu ? 'Первый черновик тура' : 'First tour draft';
      case 'first_tour_published':
        return isRu ? 'Первый тур опубликован' : 'First tour published';
      case 'three_tours_published':
        return isRu ? '3 тура опубликовано' : '3 tours published';
      case 'five_tours_published':
        return isRu ? '5 туров опубликовано' : '5 tours published';
      case 'level_2':
        return isRu ? 'Уровень 2' : 'Level 2';
      case 'level_3':
        return isRu ? 'Уровень 3' : 'Level 3';
      case 'level_5':
        return isRu ? 'Уровень 5' : 'Level 5';
      case 'level_7':
        return isRu ? 'Уровень 7' : 'Level 7';
      case 'level_8':
        return isRu ? 'Уровень 8' : 'Level 8';
      case 'level_10':
        return isRu ? 'Уровень 10' : 'Level 10';
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
        borderRadius: BorderRadius.circular(20),
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
                    fontSize: 20,
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ProfileScreenState.accent, size: 19),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : _ProfileScreenState.base;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.1) : const Color(0xFFFFF3D9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameProgressCard extends StatelessWidget {
  const _GameProgressCard({
    required this.level,
    required this.xp,
    required this.progress,
    required this.rankTitle,
    required this.progressText,
    required this.unlockedCount,
    required this.totalCount,
  });

  final int level;
  final int xp;
  final double progress;
  final String rankTitle;
  final String progressText;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151E3F), Color(0xFF263A73)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _ProfileScreenState.base.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -26,
            child: Icon(
              Icons.auto_awesome,
              size: 112,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ProfileScreenState.accent,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$level',
                          style: const TextStyle(
                            color: _ProfileScreenState.base,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          isRu ? 'ур.' : 'lvl',
                          style: const TextStyle(
                            color: _ProfileScreenState.base,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rankTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _GameMiniPill(
                              icon: Icons.bolt,
                              text: '$xp XP',
                            ),
                            _GameMiniPill(
                              icon: Icons.emoji_events_outlined,
                              text: '$unlockedCount/$totalCount',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GameXpBar(value: progress),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progressText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: _ProfileScreenState.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameMiniPill extends StatelessWidget {
  const _GameMiniPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _ProfileScreenState.accent, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameXpBar extends StatelessWidget {
  const _GameXpBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * value.clamp(0.0, 1.0);
        return Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: width,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD36B), _ProfileScreenState.accent],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: List.generate(
                    10,
                    (_) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFF7E4) : const Color(0xFFF2F3F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? _ProfileScreenState.accent.withOpacity(0.55)
              : _ProfileScreenState.base.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: unlocked
                  ? _ProfileScreenState.accent
                  : _ProfileScreenState.base.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? Icons.star_rounded : Icons.lock_outline,
              color: unlocked
                  ? _ProfileScreenState.base
                  : _ProfileScreenState.base.withOpacity(0.48),
              size: 15,
            ),
          ),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
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

class _RouteHistoryTile extends StatelessWidget {
  const _RouteHistoryTile({required this.item});

  final RouteHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final distance = item.distanceM >= 1000
        ? '${(item.distanceM / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}'
        : '${item.distanceM.toStringAsFixed(0)} ${isRu ? 'м' : 'm'}';
    final duration = item.durationS >= 3600
        ? '${(item.durationS / 3600).toStringAsFixed(1)} ${isRu ? 'ч' : 'h'}'
        : '${(item.durationS / 60).round()} ${context.l10n.minUnit}';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: _ProfileScreenState.base.withOpacity(0.1)),
      ),
      leading: const Icon(Icons.route_outlined, color: _ProfileScreenState.base),
      title: Text(
        item.destinationName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ProfileScreenState.base,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text('${_modeLabel(context, item.profile)} · $distance · $duration'),
      trailing: IconButton(
        tooltip: context.l10n.openOnMap,
        icon: const Icon(Icons.map_outlined),
        onPressed: () {
          final poi = Poi(
            id: -item.id,
            name: item.destinationName,
            description: distance,
            latitude: item.toLat,
            longitude: item.toLng,
            category: 'custom',
          );
          Navigator.pushNamed(
            context,
            Routes.map,
            arguments: AppShellArgs(initialIndex: 2, initialPoi: poi),
          );
        },
      ),
    );
  }

  String _modeLabel(BuildContext context, String mode) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    switch (mode) {
      case 'walking':
        return isRu ? 'Пешком' : 'Walking';
      case 'driving':
        return isRu ? 'Авто' : 'Driving';
      case 'cycling':
        return isRu ? 'Велосипед' : 'Cycling';
      default:
        return mode;
    }
  }
}

class _VisitedTile extends StatelessWidget {
  const _VisitedTile({required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: _ProfileScreenState.base.withOpacity(0.1)),
      ),
      leading: const Icon(Icons.place_outlined, color: _ProfileScreenState.base),
      title: Text(
        poi.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ProfileScreenState.base,
          fontWeight: FontWeight.w900,
        ),
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
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProfileScreenState.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: _ProfileScreenState.base, size: 36),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileScreenState.base,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: _ProfileScreenState.base.withOpacity(0.66)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
