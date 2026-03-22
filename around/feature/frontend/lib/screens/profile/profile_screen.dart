import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../models/poi.dart';
import '../../services/poi_service.dart';
import '../../state/auth_state.dart';

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
  bool _initialized = false;
  List<Poi> _visited = [];
  bool _loadingVisited = false;
  String? _visitedError;

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

    _loadVisited();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadVisited();
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
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Посещенные места',
                    style: TextStyle(
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
                    'Ошибка загрузки: $_visitedError',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_visited.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Пока нет посещенных мест',
                    style: TextStyle(color: base, fontWeight: FontWeight.w600),
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
                            child: const Icon(
                              Icons.place_outlined,
                              color: base,
                            ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Посещено',
                              style: TextStyle(
                                color: base,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
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
