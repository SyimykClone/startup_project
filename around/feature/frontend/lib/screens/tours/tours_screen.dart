import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_client.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../../state/auth_state.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key, required this.refreshTick});

  final int refreshTick;

  static const _base = Color(0xFF151E3F);

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
    final durationCtrl = TextEditingController(text: tour?.durationDays.toString() ?? '');
    final priceCtrl = TextEditingController(text: tour?.price.toStringAsFixed(0) ?? '');
    final distanceCtrl = TextEditingController(text: tour?.distanceKm.toStringAsFixed(1) ?? '');
    final stopsCtrl = TextEditingController(text: tour?.stopsCount.toString() ?? '');
    var selectedDifficulty = tour?.difficulty ?? 'easy';
    var isPublished = tour?.isPublished ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(tour == null ? l10n.createTour : l10n.editTour),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(labelText: l10n.tourTitle),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l10n.tourDescription),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.tourDurationDays),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.tourPrice),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: distanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.tourDistanceKm),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stopsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.tourStopsCount),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDifficulty,
                      decoration: InputDecoration(labelText: l10n.tourDifficulty),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedDifficulty = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: isPublished,
                      onChanged: (value) => setModalState(() => isPublished = value),
                      title: Text(l10n.tourPublished),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final l10n = context.l10n;

    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    final duration = int.tryParse(durationCtrl.text.trim());
    final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
    final distance = double.tryParse(distanceCtrl.text.trim().replaceAll(',', '.'));
    final stopsCount = int.tryParse(stopsCtrl.text.trim());

    if (title.length < 3 ||
        description.length < 3 ||
        duration == null ||
        price == null ||
        distance == null ||
        stopsCount == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkFormData)),
      );
      return;
    }

    try {
      if (tour == null) {
        await _tourService!.create(
          title: title,
          description: description,
          durationDays: duration,
          price: price,
          distanceKm: distance,
          stopsCount: stopsCount,
          difficulty: selectedDifficulty,
          isPublished: isPublished,
        );
      } else {
        await _tourService!.update(
          tour.id,
          title: title,
          description: description,
          durationDays: duration,
          price: price,
          distanceKm: distance,
          stopsCount: stopsCount,
          difficulty: selectedDifficulty,
          isPublished: isPublished,
        );
      }
      await _loadTours();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loadError(e.toString()))),
      );
    }
  }

  Future<void> _deleteTour(Tour tour) async {
    if (_tourService == null) return;
    final l10n = context.l10n;
    try {
      await _tourService!.delete(tour.id);
      await _loadTours();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
      );
    }
  }

  String _difficultyLabel(String value, dynamic l10n) {
    switch (value) {
      case 'easy':
        return l10n.difficultyEasy;
      case 'medium':
        return l10n.difficultyMedium;
      case 'hard':
        return l10n.difficultyHard;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = context.watch<AuthState>().isBusiness;
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
                    isBusiness ? l10n.myToursTitle : l10n.toursTitle,
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
                    label: Text(l10n.createTour),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isBusiness
                  ? l10n.toursBusinessHint
                  : l10n.toursUserHint,
              style: TextStyle(color: ToursScreen._base.withOpacity(0.7)),
            ),
            const SizedBox(height: 14),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(l10n.loadError(_error!)),
              ),
            Expanded(
              child: _tours.isEmpty
                  ? Center(child: Text(l10n.noToursYet))
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
                                    if (isBusiness)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: tour.isPublished
                                              ? const Color(0xFFE7F7EE)
                                              : const Color(0xFFFFF3D9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tour.isPublished ? l10n.published : l10n.draft,
                                          style: const TextStyle(
                                            color: ToursScreen._base,
                                            fontSize: 11,
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
                                      text: '${tour.durationDays} ${l10n.daysUnit}',
                                    ),
                                    _InfoChip(
                                      icon: Icons.payments_outlined,
                                      text: '\$${tour.price.toStringAsFixed(0)}',
                                    ),
                                    _InfoChip(
                                      icon: Icons.route_outlined,
                                      text: '${tour.distanceKm.toStringAsFixed(1)} km',
                                    ),
                                    _InfoChip(
                                      icon: Icons.place_outlined,
                                      text: '${tour.stopsCount} ${l10n.stopsUnit}',
                                    ),
                                    _InfoChip(
                                      icon: Icons.speed_outlined,
                                      text: _difficultyLabel(tour.difficulty, l10n),
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
