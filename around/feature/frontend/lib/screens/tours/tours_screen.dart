import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../../state/auth_state.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key, required this.refreshTick});

  final int refreshTick;

  static const _base = Color(0xFF151E3F);
  static const _accent = Color(0xFFFAA916);

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  TourService? _tourService;
  bool _loading = false;
  String? _error;
  List<Tour> _tours = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tourService != null) return;
    final cfg = context.read<AppConfig>();
    final token = context.read<AuthState>().token;
    _tourService = TourService(ApiClient(cfg.apiBaseUrl, token: token));
    _loadTours();
  }

  @override
  void didUpdateWidget(covariant ToursScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadTours();
    }
  }

  Future<void> _loadTours() async {
    if (_tourService == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final isBusiness = context.read<AuthState>().isBusiness;
      final data = isBusiness
          ? await _tourService!.fetchMine()
          : await _tourService!.fetchAll();
      if (!mounted) return;
      setState(() => _tours = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openTourDialog({Tour? tour}) async {
    if (_tourService == null) return;
    final titleCtrl = TextEditingController(text: tour?.title ?? '');
    final descCtrl = TextEditingController(text: tour?.description ?? '');
    final durationCtrl = TextEditingController(
      text: tour?.durationMin.toString() ?? '',
    );
    final distanceCtrl = TextEditingController(
      text: tour?.distanceKm.toStringAsFixed(1) ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tour == null ? 'Создать тур' : 'Редактировать тур'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Длительность (мин)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: distanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Дистанция (км)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    final duration = int.tryParse(durationCtrl.text.trim());
    final distance = double.tryParse(distanceCtrl.text.trim().replaceAll(',', '.'));

    if (title.length < 3 ||
        description.length < 3 ||
        duration == null ||
        distance == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверьте данные формы')),
      );
      return;
    }

    try {
      if (tour == null) {
        await _tourService!.create(
          title: title,
          description: description,
          durationMin: duration,
          distanceKm: distance,
        );
      } else {
        await _tourService!.update(
          tour.id,
          title: title,
          description: description,
          durationMin: duration,
          distanceKm: distance,
        );
      }
      await _loadTours();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ')));
    }
  }

  Future<void> _deleteTour(Tour tour) async {
    if (_tourService == null) return;
    try {
      await _tourService!.delete(tour.id);
      await _loadTours();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось удалить: ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = context.watch<AuthState>().isBusiness;

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
                    isBusiness ? 'Мои туры' : 'Туры',
                    style: const TextStyle(
                      color: ToursScreen._base,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isBusiness)
                  FilledButton.icon(
                    onPressed: () => _openTourDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isBusiness
                  ? 'Вы видите и управляете только своими турами'
                  : 'Доступные туры от бизнес-пользователей',
              style: TextStyle(color: ToursScreen._base.withOpacity(0.7)),
            ),
            const SizedBox(height: 14),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Ошибка загрузки: '),
              ),
            Expanded(
              child: _tours.isEmpty
                  ? const Center(child: Text('Пока нет туров'))
                  : RefreshIndicator(
                      onRefresh: _loadTours,
                      child: ListView.separated(
                        itemCount: _tours.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final tour = _tours[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ToursScreen._base.withOpacity(0.14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tour.title,
                                        style: const TextStyle(
                                          color: ToursScreen._base,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isBusiness) ...[
                                      IconButton(
                                        onPressed: () => _openTourDialog(tour: tour),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteTour(tour),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tour.description,
                                  style: TextStyle(
                                    color: ToursScreen._base.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(
                                      icon: Icons.schedule_outlined,
                                      text: ' min',
                                    ),
                                    _InfoChip(
                                      icon: Icons.route_outlined,
                                      text: ' km',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ToursScreen._base),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: ToursScreen._base,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
