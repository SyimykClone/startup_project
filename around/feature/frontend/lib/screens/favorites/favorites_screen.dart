import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_client.dart';
import '../../models/poi.dart';
import '../../services/poi_service.dart';
import '../../state/auth_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.refreshTick});

  final int refreshTick;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const accent = Color(0xFFFAA916);
  static const base = Color(0xFF151E3F);

  late PoiService _poiService;
  bool _initialized = false;
  bool _loading = false;
  String? _error;
  List<Poi> _favorites = [];

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

    _loadFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _poiService.fetchFavorites();
      if (!mounted) return;
      setState(() => _favorites = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndRemoveFavorite(Poi poi) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFavoriteTitle),
        content: Text(l10n.removeFavoriteMessage(poi.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _poiService.removeFavorite(poi.id);
      if (!mounted) return;
      setState(() => _favorites.removeWhere((p) => p.id == poi.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.removeFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                    l10n.favoritesTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: base,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _loadFavorites,
                  icon: const Icon(Icons.refresh, color: base),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.loadError(_error!),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _loadFavorites,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              )
            else if (_favorites.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.favoritesEmpty,
                    style: const TextStyle(
                      color: base,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final poi = _favorites[index];
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
                              color: const Color(0xFFFFF3D9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.favorite, color: accent),
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
                          OutlinedButton(
                            onPressed: () => _confirmAndRemoveFavorite(poi),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: accent),
                              foregroundColor: base,
                            ),
                            child: Text(l10n.remove),
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
}
