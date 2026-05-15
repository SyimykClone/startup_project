import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../../state/auth_state.dart';
import '../../utils/app_error_text.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key, required this.refreshTick});

  final int refreshTick;

  static const base = Color(0xFF151E3F);
  static const accent = Color(0xFFFAA916);
  static const soft = Color(0xFFF6F7FB);

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  TourService? _tourService;
  bool _loading = false;
  String? _error;
  List<Tour> _tours = const [];
  String _difficultyFilter = 'all';
  String _sortMode = 'recommended';

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

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
    if (oldWidget.refreshTick != widget.refreshTick) _loadTours();
  }

  List<Tour> get _visibleTours {
    final filtered = _difficultyFilter == 'all'
        ? [..._tours]
        : _tours.where((tour) => tour.difficulty == _difficultyFilter).toList();

    switch (_sortMode) {
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'duration':
        filtered.sort((a, b) => a.durationDays.compareTo(b.durationDays));
      case 'distance':
        filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      default:
        filtered.sort((a, b) {
          final aScore = a.stopsCount * 2 + a.durationDays;
          final bScore = b.stopsCount * 2 + b.durationDays;
          return bScore.compareTo(aScore);
        });
    }

    return filtered;
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
      setState(() => _error = AppErrorText.fromObject(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTourEditor({Tour? tour}) async {
    if (_tourService == null) return;

    final result = await showModalBottomSheet<_TourFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _TourEditorSheet(tour: tour),
    );
    if (result == null) return;

    try {
      if (tour == null) {
        await _tourService!.create(
          title: result.title,
          description: result.description,
          durationDays: result.durationDays,
          price: result.price,
          distanceKm: result.distanceKm,
          stopsCount: result.stopsCount,
          difficulty: result.difficulty,
          isPublished: result.isPublished,
        );
      } else {
        await _tourService!.update(
          tour.id,
          title: result.title,
          description: result.description,
          durationDays: result.durationDays,
          price: result.price,
          distanceKm: result.distanceKm,
          stopsCount: result.stopsCount,
          difficulty: result.difficulty,
          isPublished: result.isPublished,
        );
      }
      await _loadTours();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorText.fromObject(context, e))),
      );
    }
  }

  Future<void> _deleteTour(Tour tour) async {
    if (_tourService == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isRu ? 'Удалить тур?' : 'Delete tour?'),
        content: Text(
          _isRu
              ? 'Тур "${tour.title}" будет удален без возможности восстановления.'
              : 'Tour "${tour.title}" will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isRu ? 'Удалить' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _tourService!.delete(tour.id);
      await _loadTours();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorText.fromObject(context, e))),
      );
    }
  }

  void _openTourDetails(Tour tour, bool isBusiness) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _TourDetailsSheet(
        tour: tour,
        isBusiness: isBusiness,
        priceLabel: _priceLabel(tour),
        difficultyLabel: _difficultyLabel(tour.difficulty),
        onBook: isBusiness ? null : () => _openBookingSheet(tour),
        onOpenMap: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            Routes.map,
            arguments: const AppShellArgs(initialIndex: 2),
          );
        },
      ),
    );
  }

  void _openBookingSheet(Tour tour) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _BookingSheet(
        tour: tour,
        priceLabel: _priceLabel(tour),
        onConfirmed: (people) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isRu
                    ? 'Заявка на тур отправлена. Участников: $people'
                    : 'Tour request sent. Guests: $people',
              ),
            ),
          );
        },
      ),
    );
  }

  String _difficultyLabel(String value) {
    final l10n = context.l10n;
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

  String _priceLabel(Tour tour) {
    final amount = tour.price.toStringAsFixed(0);
    return _isRu ? '$amount сом' : '$amount som';
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = context.watch<AuthState>().isBusiness;
    final l10n = context.l10n;
    final visibleTours = isBusiness ? _tours : _visibleTours;
    final publishedCount = _tours.where((tour) => tour.isPublished).length;
    final draftCount = _tours.length - publishedCount;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTours,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _ToursHero(
              title: isBusiness ? l10n.myToursTitle : l10n.toursTitle,
              subtitle: isBusiness ? l10n.toursBusinessHint : l10n.toursUserHint,
              isBusiness: isBusiness,
              toursCount: _tours.length,
              onCreate: () => _openTourEditor(),
            ),
            if (isBusiness) ...[
              const SizedBox(height: 12),
              _BusinessTourPanel(
                publishedCount: publishedCount,
                draftCount: draftCount,
              ),
            ],
            if (!isBusiness) ...[
              const SizedBox(height: 12),
              _TourFilters(
                difficulty: _difficultyFilter,
                sortMode: _sortMode,
                onDifficultyChanged: (value) => setState(() => _difficultyFilter = value),
                onSortChanged: (value) => setState(() => _sortMode = value),
                difficultyLabel: _difficultyLabel,
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _EmptyState(
                icon: Icons.cloud_off_outlined,
                title: _isRu ? 'Не удалось загрузить туры' : 'Could not load tours',
                text: context.l10n.loadError(_error!),
                actionLabel: _isRu ? 'Повторить' : 'Retry',
                onAction: _loadTours,
              ),
            ] else if (!_loading && _tours.isEmpty) ...[
              const SizedBox(height: 14),
              _EmptyState(
                icon: Icons.hiking_outlined,
                title: l10n.noToursYet,
                text: isBusiness
                    ? (_isRu
                        ? 'Создайте первый тур: программа, цена в сомах, остановки и публикация.'
                        : 'Create your first tour with itinerary, price in som, stops and publishing.')
                    : (_isRu
                        ? 'Опубликованные туры появятся здесь после добавления бизнес-пользователями.'
                        : 'Published tours will appear here after business users add them.'),
                actionLabel: null,
                onAction: null,
              ),
            ] else if (!isBusiness && !_loading && visibleTours.isEmpty) ...[
              const SizedBox(height: 14),
              _EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: _isRu ? 'Нет туров по фильтру' : 'No tours match filters',
                text: _isRu
                    ? 'Измените сложность или сортировку, чтобы увидеть больше вариантов.'
                    : 'Change difficulty or sorting to see more options.',
                actionLabel: _isRu ? 'Сбросить' : 'Reset',
                onAction: () => setState(() {
                  _difficultyFilter = 'all';
                  _sortMode = 'recommended';
                }),
              ),
            ] else ...[
              const SizedBox(height: 14),
              ...visibleTours.map(
                (tour) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TourCard(
                    tour: tour,
                    isBusiness: isBusiness,
                    priceLabel: _priceLabel(tour),
                    difficultyLabel: _difficultyLabel(tour.difficulty),
                    onDetails: () => _openTourDetails(tour, isBusiness),
                    onBook: isBusiness ? null : () => _openBookingSheet(tour),
                    onEdit: () => _openTourEditor(tour: tour),
                    onDelete: () => _deleteTour(tour),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToursHero extends StatelessWidget {
  const _ToursHero({
    required this.title,
    required this.subtitle,
    required this.isBusiness,
    required this.toursCount,
    required this.onCreate,
  });

  final String title;
  final String subtitle;
  final bool isBusiness;
  final int toursCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ToursScreen.base,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore_outlined, color: ToursScreen.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroPill(
                icon: Icons.map_outlined,
                text: isRu ? '$toursCount туров' : '$toursCount tours',
              ),
              const Spacer(),
              if (isBusiness)
                FilledButton.icon(
                  onPressed: onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: ToursScreen.accent,
                    foregroundColor: ToursScreen.base,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.createTour),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TourFilters extends StatelessWidget {
  const _TourFilters({
    required this.difficulty,
    required this.sortMode,
    required this.onDifficultyChanged,
    required this.onSortChanged,
    required this.difficultyLabel,
  });

  final String difficulty;
  final String sortMode;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<String> onSortChanged;
  final String Function(String value) difficultyLabel;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final filters = ['all', 'easy', 'medium', 'hard'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isRu ? 'Сложность' : 'Difficulty',
              style: const TextStyle(
                color: ToursScreen.base,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final value = filters[index];
                    final selected = difficulty == value;
                    final label = value == 'all'
                        ? (isRu ? 'Все' : 'All')
                        : difficultyLabel(value);
                    return ChoiceChip(
                      selected: selected,
                      label: Text(label),
                      onSelected: (_) => onDifficultyChanged(value),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: sortMode,
          decoration: InputDecoration(
            labelText: isRu ? 'Сортировка' : 'Sorting',
            isDense: true,
          ),
          items: [
            DropdownMenuItem(
              value: 'recommended',
              child: Text(isRu ? 'Рекомендуемые' : 'Recommended'),
            ),
            DropdownMenuItem(
              value: 'price',
              child: Text(isRu ? 'Сначала дешевле' : 'Lowest price'),
            ),
            DropdownMenuItem(
              value: 'duration',
              child: Text(isRu ? 'По длительности' : 'By duration'),
            ),
            DropdownMenuItem(
              value: 'distance',
              child: Text(isRu ? 'По дистанции' : 'By distance'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
        ),
      ],
    );
  }
}

class _BusinessTourPanel extends StatelessWidget {
  const _BusinessTourPanel({
    required this.publishedCount,
    required this.draftCount,
  });

  final int publishedCount;
  final int draftCount;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ToursScreen.base.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: ToursScreen.base.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoChip(
              icon: Icons.public_outlined,
              text: isRu ? '$publishedCount опубликовано' : '$publishedCount published',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoChip(
              icon: Icons.edit_note_outlined,
              text: isRu ? '$draftCount черновиков' : '$draftCount drafts',
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.tour,
    required this.isBusiness,
    required this.priceLabel,
    required this.difficultyLabel,
    required this.onDetails,
    required this.onBook,
    required this.onEdit,
    required this.onDelete,
  });

  final Tour tour;
  final bool isBusiness;
  final String priceLabel;
  final String difficultyLabel;
  final VoidCallback onDetails;
  final VoidCallback? onBook;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ToursScreen.base.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 126,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [Color(0xFF151E3F), Color(0xFF293A75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    bottom: -28,
                    child: Icon(
                      Icons.terrain_outlined,
                      color: Colors.white.withOpacity(0.12),
                      size: 136,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tour.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (isBusiness)
                              _StatusPill(
                                text: tour.isPublished ? l10n.published : l10n.draft,
                                published: tour.isPublished,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                color: ToursScreen.accent,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRu ? 'за человека' : 'per person',
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ToursScreen.base.withOpacity(0.76),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_outlined,
                        text: '${tour.durationDays} ${l10n.daysUnit}',
                      ),
                      _InfoChip(
                        icon: Icons.route_outlined,
                        text: '${tour.distanceKm.toStringAsFixed(1)} ${l10n.kmUnit}',
                      ),
                      _InfoChip(
                        icon: Icons.place_outlined,
                        text: '${tour.stopsCount} ${l10n.stopsUnit}',
                      ),
                      _InfoChip(icon: Icons.speed_outlined, text: difficultyLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDetails,
                          icon: const Icon(Icons.list_alt_outlined, size: 18),
                          label: Text(isRu ? 'Программа' : 'Itinerary'),
                        ),
                      ),
                      if (onBook != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onBook,
                            icon: const Icon(Icons.event_available_outlined, size: 18),
                            label: Text(isRu ? 'Заявка' : 'Book'),
                          ),
                        ),
                      ],
                      if (isBusiness) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: l10n.editTour,
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: isRu ? 'Удалить' : 'Delete',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourDetailsSheet extends StatelessWidget {
  const _TourDetailsSheet({
    required this.tour,
    required this.isBusiness,
    required this.priceLabel,
    required this.difficultyLabel,
    required this.onBook,
    required this.onOpenMap,
  });

  final Tour tour;
  final bool isBusiness;
  final String priceLabel;
  final String difficultyLabel;
  final VoidCallback? onBook;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tour.title,
                    style: const TextStyle(
                      color: ToursScreen.base,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isBusiness)
                  _StatusPill(
                    text: tour.isPublished ? l10n.published : l10n.draft,
                    published: tour.isPublished,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tour.description,
              style: TextStyle(
                color: ToursScreen.base.withOpacity(0.76),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.payments_outlined, text: priceLabel),
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  text: '${tour.durationDays} ${l10n.daysUnit}',
                ),
                _InfoChip(
                  icon: Icons.route_outlined,
                  text: '${tour.distanceKm.toStringAsFixed(1)} ${l10n.kmUnit}',
                ),
                _InfoChip(
                  icon: Icons.place_outlined,
                  text: '${tour.stopsCount} ${l10n.stopsUnit}',
                ),
                _InfoChip(icon: Icons.speed_outlined, text: difficultyLabel),
              ],
            ),
            const SizedBox(height: 18),
            _SheetTitle(isRu ? 'Программа тура' : 'Tour itinerary'),
            const SizedBox(height: 10),
            ..._buildItinerary(context, tour),
            const SizedBox(height: 16),
            _SheetTitle(isRu ? 'Условия' : 'Terms'),
            const SizedBox(height: 8),
            _BenefitRow(text: isRu ? 'Цена указана за одного человека' : 'Price is per person'),
            _BenefitRow(text: isRu ? 'Маршрут можно открыть на карте приложения' : 'Route can be opened on the app map'),
            _BenefitRow(text: isRu ? 'Заявка сохраняется как запрос на участие' : 'Booking creates a participation request'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(isRu ? 'Карта' : 'Map'),
                  ),
                ),
                if (onBook != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onBook,
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(isRu ? 'Оставить заявку' : 'Book'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItinerary(BuildContext context, Tour tour) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final count = tour.stopsCount <= 0 ? 1 : tour.stopsCount;
    return List.generate(count, (index) {
      final isFirst = index == 0;
      final isLast = index == count - 1;
      final title = isFirst
          ? (isRu ? 'Старт и встреча' : 'Start and meeting')
          : isLast
              ? (isRu ? 'Финальная остановка' : 'Final stop')
              : (isRu ? 'Остановка ${index + 1}' : 'Stop ${index + 1}');
      final text = isFirst
          ? (isRu
              ? 'Сбор группы, знакомство с маршрутом и правилами тура.'
              : 'Group meetup, route overview and tour rules.')
          : isLast
              ? (isRu
                  ? 'Завершение маршрута, свободное время и возвращение.'
                  : 'Route finish, free time and return.')
              : (isRu
                  ? 'Осмотр точки, краткая справка и время для фото.'
                  : 'Point visit, short story and photo time.');
      return _TimelineItem(number: index + 1, title: title, text: text);
    });
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({
    required this.tour,
    required this.priceLabel,
    required this.onConfirmed,
  });

  final Tour tour;
  final String priceLabel;
  final ValueChanged<int> onConfirmed;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  int _people = 1;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final total = widget.tour.price * _people;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRu ? 'Заявка на тур' : 'Tour request',
            style: const TextStyle(
              color: ToursScreen.base,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.tour.title,
            style: TextStyle(
              color: ToursScreen.base.withOpacity(0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ToursScreen.soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isRu ? 'Количество участников' : 'Guests',
                    style: const TextStyle(
                      color: ToursScreen.base,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _people <= 1 ? null : () => setState(() => _people--),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_people',
                  style: const TextStyle(
                    color: ToursScreen.base,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _people++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isRu
                ? 'Итого: ${total.toStringAsFixed(0)} сом'
                : 'Total: ${total.toStringAsFixed(0)} som',
            style: const TextStyle(
              color: ToursScreen.base,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => widget.onConfirmed(_people),
              icon: const Icon(Icons.send_outlined),
              label: Text(isRu ? 'Отправить заявку' : 'Send request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourEditorSheet extends StatefulWidget {
  const _TourEditorSheet({this.tour});

  final Tour? tour;

  @override
  State<_TourEditorSheet> createState() => _TourEditorSheetState();
}

class _TourEditorSheetState extends State<_TourEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _duration;
  late final TextEditingController _price;
  late final TextEditingController _distance;
  late final TextEditingController _stops;
  late String _difficulty;
  late bool _published;

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    final tour = widget.tour;
    _title = TextEditingController(text: tour?.title ?? '');
    _description = TextEditingController(text: tour?.description ?? '');
    _duration = TextEditingController(text: tour?.durationDays.toString() ?? '');
    _price = TextEditingController(text: tour?.price.toStringAsFixed(0) ?? '');
    _distance = TextEditingController(text: tour?.distanceKm.toStringAsFixed(1) ?? '');
    _stops = TextEditingController(text: tour?.stopsCount.toString() ?? '');
    _difficulty = tour?.difficulty ?? 'easy';
    _published = tour?.isPublished ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    _distance.dispose();
    _stops.dispose();
    super.dispose();
  }

  void _save() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    Navigator.pop(
      context,
      _TourFormResult(
        title: _title.text.trim(),
        description: _description.text.trim(),
        durationDays: int.parse(_duration.text.trim()),
        price: double.parse(_price.text.trim().replaceAll(',', '.')),
        distanceKm: double.parse(_distance.text.trim().replaceAll(',', '.')),
        stopsCount: int.parse(_stops.text.trim()),
        difficulty: _difficulty,
        isPublished: _published,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.tour != null;
    return Container(
      color: ToursScreen.base,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ToursScreen.base,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: ToursScreen.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.travel_explore_outlined,
                            color: ToursScreen.base,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? l10n.editTour : l10n.createTour,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRu
                                    ? 'Соберите понятное предложение: маршрут, цена, темп и публикация.'
                                    : 'Build a clear tour: route, price, pace and publishing.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EditorGroup(
                    icon: Icons.badge_outlined,
                    title: _isRu ? 'Карточка тура' : 'Tour card',
                    subtitle: _isRu
                        ? 'Название и описание должны быстро объяснить ценность маршрута.'
                        : 'Title and description should quickly explain the route value.',
                    children: [
                      TextFormField(
                        controller: _title,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.tourTitle,
                          floatingLabelStyle: const TextStyle(fontSize: 12),
                          hintText: _isRu
                              ? 'Например: Исторический Токмок'
                              : 'Example: Historic Tokmok',
                          prefixIcon: const Icon(Icons.flag_outlined),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 18,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) {
                            return l10n.checkFormData;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: l10n.tourDescription,
                          floatingLabelStyle: const TextStyle(fontSize: 12),
                          hintText: _isRu
                              ? 'Что входит, какие места увидит человек, кому подойдет тур'
                              : 'Briefly: what is included, places and target audience',
                          prefixIcon: const Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 18,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) {
                            return l10n.checkFormData;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditorGroup(
                    icon: Icons.route_outlined,
                    title: _isRu ? 'Маршрут и условия' : 'Route and terms',
                    subtitle: _isRu
                        ? 'Эти данные помогают оценить время, бюджет и нагрузку.'
                        : 'These details help users estimate time, budget and effort.',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _duration,
                              label: _isRu ? 'Дни' : 'Days',
                              icon: Icons.calendar_today_outlined,
                              integerOnly: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _NumberField(
                              controller: _price,
                              label: _isRu ? 'Цена' : 'Price',
                              icon: Icons.payments_outlined,
                              suffix: _isRu ? 'сом' : 'som',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _distance,
                              label: _isRu ? 'Дистанция' : 'Distance',
                              icon: Icons.straighten_outlined,
                              suffix: l10n.kmUnit,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _NumberField(
                              controller: _stops,
                              label: _isRu ? 'Остановки' : 'Stops',
                              icon: Icons.place_outlined,
                              integerOnly: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _DifficultySelector(
                        value: _difficulty,
                        onChanged: (value) =>
                            setState(() => _difficulty = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TourDraftPreview(
                    title: _title,
                    price: _price,
                    duration: _duration,
                    stops: _stops,
                    difficulty: _difficulty,
                  ),
                  const SizedBox(height: 12),
                  _PublishCard(
                    value: _published,
                    onChanged: (value) => setState(() => _published = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ToursScreen.base,
                            side: BorderSide(
                              color: ToursScreen.base.withOpacity(0.28),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: ToursScreen.accent,
                            foregroundColor: ToursScreen.base,
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l10n.save),
                        ),
                      ),
                    ],
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.icon,
    this.suffix,
    this.integerOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? suffix;
  final bool integerOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon == null ? null : Icon(icon),
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
      ),
      validator: (value) {
        final text = (value ?? '').trim().replaceAll(',', '.');
        final number = integerOnly ? int.tryParse(text) : double.tryParse(text);
        if (number == null || number < 0) return context.l10n.checkFormData;
        if (integerOnly && number == 0) return context.l10n.checkFormData;
        return null;
      },
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final options = [
      (value: 'easy', label: l10n.difficultyEasy, icon: Icons.directions_walk),
      (value: 'medium', label: l10n.difficultyMedium, icon: Icons.hiking),
      (value: 'hard', label: l10n.difficultyHard, icon: Icons.terrain),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tourDifficulty,
          style: const TextStyle(
            color: ToursScreen.base,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final option in options) ...[
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onChanged(option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: value == option.value
                          ? ToursScreen.accent
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: value == option.value
                            ? ToursScreen.accent
                            : ToursScreen.base.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(option.icon, color: ToursScreen.base, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ToursScreen.base,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (option.value != options.last.value) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isRu
              ? 'Сложность будет использоваться в подборе тура для обычных пользователей.'
              : 'Difficulty is used for regular users tour matching.',
          style: TextStyle(
            color: ToursScreen.base.withOpacity(0.58),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PublishCard extends StatelessWidget {
  const _PublishCard({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFEFFAF1) : const Color(0xFFFFF7E4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? Colors.green.withOpacity(0.22)
              : ToursScreen.accent.withOpacity(0.26),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: value ? Colors.green : ToursScreen.accent,
            foregroundColor: value ? Colors.white : ToursScreen.base,
            child: Icon(value ? Icons.public_outlined : Icons.edit_note_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tourPublished,
                  style: const TextStyle(
                    color: ToursScreen.base,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value
                      ? (isRu
                          ? 'Тур будет виден обычным пользователям.'
                          : 'The tour will be visible to regular users.')
                      : (isRu
                          ? 'Сохранится как черновик, его можно дописать позже.'
                          : 'Saved as a draft, you can finish it later.'),
                  style: TextStyle(color: ToursScreen.base.withOpacity(0.64)),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TourDraftPreview extends StatelessWidget {
  const _TourDraftPreview({
    required this.title,
    required this.price,
    required this.duration,
    required this.stops,
    required this.difficulty,
  });

  final TextEditingController title;
  final TextEditingController price;
  final TextEditingController duration;
  final TextEditingController stops;
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return AnimatedBuilder(
      animation: Listenable.merge([title, price, duration, stops]),
      builder: (context, _) {
        final titleText = title.text.trim().isEmpty
            ? (isRu ? 'Название тура' : 'Tour title')
            : title.text.trim();
        final priceText = price.text.trim().isEmpty
            ? (isRu ? 'Цена' : 'Price')
            : '${price.text.trim()} ${isRu ? 'сом' : 'som'}';
        final durationText = duration.text.trim().isEmpty
            ? (isRu ? 'Дни' : 'Days')
            : '${duration.text.trim()} ${context.l10n.daysUnit}';
        final stopsText = stops.text.trim().isEmpty
            ? (isRu ? 'Остановки' : 'Stops')
            : '${stops.text.trim()} ${context.l10n.stopsUnit}';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ToursScreen.base,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ToursScreen.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.card_travel_outlined,
                      color: ToursScreen.base,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRu ? 'Предпросмотр тура' : 'Tour preview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PreviewChip(icon: Icons.payments_outlined, text: priceText),
                  _PreviewChip(
                    icon: Icons.calendar_today_outlined,
                    text: durationText,
                  ),
                  _PreviewChip(icon: Icons.place_outlined, text: stopsText),
                  _PreviewChip(
                    icon: Icons.speed_outlined,
                    text: _difficultyText(context, difficulty),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _difficultyText(BuildContext context, String value) {
    final l10n = context.l10n;
    switch (value) {
      case 'medium':
        return l10n.difficultyMedium;
      case 'hard':
        return l10n.difficultyHard;
      default:
        return l10n.difficultyEasy;
    }
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ToursScreen.accent),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.number,
    required this.title,
    required this.text,
  });

  final int number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: ToursScreen.accent,
            foregroundColor: ToursScreen.base,
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ToursScreen.base,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(color: ToursScreen.base.withOpacity(0.68)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ToursScreen.base,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EditorGroup extends StatelessWidget {
  const _EditorGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ToursScreen.base.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: ToursScreen.base.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ToursScreen.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ToursScreen.base, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ToursScreen.base,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ToursScreen.base.withOpacity(0.58),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TourFormResult {
  const _TourFormResult({
    required this.title,
    required this.description,
    required this.durationDays,
    required this.price,
    required this.distanceKm,
    required this.stopsCount,
    required this.difficulty,
    required this.isPublished,
  });

  final String title;
  final String description;
  final int durationDays;
  final double price;
  final double distanceKm;
  final int stopsCount;
  final String difficulty;
  final bool isPublished;
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: ToursScreen.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: ToursScreen.base.withOpacity(0.76)),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ToursScreen.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ToursScreen.base),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: ToursScreen.base,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.published});

  final String text;
  final bool published;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: published ? const Color(0xFFE7F7EE) : const Color(0xFFFFF3D9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ToursScreen.base,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ToursScreen.base.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: ToursScreen.base, size: 42),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ToursScreen.base,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: ToursScreen.base.withOpacity(0.68)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
