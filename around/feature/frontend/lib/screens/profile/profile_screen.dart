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

  String _detailsLabel() =>
      Localizations.localeOf(context).languageCode == 'ru'
          ? 'Подробнее'
          : 'Details';

  String _openMapLabel() =>
      Localizations.localeOf(context).languageCode == 'ru'
          ? 'Открыть на карте'
          : 'Open on map';

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
    final l10n = context.l10n;
    final auth = context.watch<AuthState>();
    final rawUsername = auth.username?.trim();
    final username =
        rawUsername == null || rawUsername.isEmpty || rawUsername.toLowerCase() == 'user'
            ? _fallbackUsername()
            : rawUsername;
    final avatarUrl = auth.avatarUrl;
    final localeState = context.watch<LocaleState>();

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
                  PopupMenuButton<String>(
                    tooltip: l10n.language,
                    onSelected: (value) {
                      context.read<LocaleState>().setLocale(Locale(value));
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'ru',
                        child: Row(
                          children: [
                            Icon(
                              localeState.locale.languageCode == 'ru'
                                  ? Icons.check
                                  : Icons.language,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.russian),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Icon(
                              localeState.locale.languageCode == 'en'
                                  ? Icons.check
                                  : Icons.language,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.english),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localeState.locale.languageCode.toUpperCase(),
                        style: const TextStyle(
                          color: base,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, Routes.editProfile),
                    borderRadius: BorderRadius.circular(44),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF8E8),
                        border: Border.all(color: accent.withOpacity(0.8), width: 1.4),
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildGamificationCard(context),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.visitedTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: base,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadingVisited ? null : _loadVisited,
                  icon: const Icon(Icons.refresh, color: base),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingVisited)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_visitedError != null)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.loadError(_visitedError!),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_visited.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.visitedEmpty,
                    style: const TextStyle(color: base, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _visited.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final poi = _visited[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: base.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.place_outlined, color: base),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  poi.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: base,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  poi.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: base.withOpacity(0.65),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'details') {
                                Navigator.pushNamed(
                                  context,
                                  Routes.poiDetail,
                                  arguments: poi,
                                );
                              }
                              if (value == 'map') {
                                Navigator.pushNamed(
                                  context,
                                  Routes.map,
                                  arguments: AppShellArgs(
                                    initialIndex: 2,
                                    initialPoi: poi,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3D9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.visitedBadge,
                                style: const TextStyle(
                                  color: base,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'details',
                                child: Text(_detailsLabel()),
                              ),
                              PopupMenuItem(
                                value: 'map',
                                child: Text(_openMapLabel()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationCard(BuildContext context) {
    const border = Color(0x1A151E3F);
    if (_loadingProgress) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_progressError != null || _progress == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.gamificationTitle,
              style: const TextStyle(
                color: base,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.loadError(_progressError ?? 'empty response')),
          ],
        ),
      );
    }

    final p = _progress!;
    final progress = (p.xpProgressPercent / 100).clamp(0.0, 1.0);
    final nextLevel = p.nextLevelXp?.toString() ?? context.l10n.maxLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.gamificationTitle,
            style: const TextStyle(
              color: base,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.levelLine(p.level, p.xp),
            style: const TextStyle(color: base, fontWeight: FontWeight.w700),
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
            context.l10n.xpToNextLevel(nextLevel),
            style: TextStyle(color: base.withOpacity(0.75), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.routesBuiltLabel(p.routesBuilt),
            style: const TextStyle(color: base, fontWeight: FontWeight.w600),
          ),
          Text(
            context.l10n.newPlacesLabel(p.newPlacesVisited),
            style: const TextStyle(color: base, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.achievementsTitle,
            style: const TextStyle(color: base, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...p.achievements.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(
                    a.unlocked ? Icons.emoji_events : Icons.lock_outline,
                    size: 16,
                    color: a.unlocked ? accent : base.withOpacity(0.45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _achievementTitle(context, a.code, a.title),
                      style: TextStyle(
                        color: a.unlocked ? base : base.withOpacity(0.7),
                        fontWeight: a.unlocked
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
