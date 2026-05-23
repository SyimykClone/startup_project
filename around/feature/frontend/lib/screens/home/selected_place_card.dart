part of 'map_screen.dart';

class _SelectedPoiCard extends StatelessWidget {
  const _SelectedPoiCard({
    required this.poiLoading,
    required this.routeLoading,
    required this.selectedPoi,
    required this.isFavorite,
    required this.routeActive,
    required this.routeSummary,
    required this.showRouteSummaryGap,
    required this.routeError,
    required this.distanceLabel,
    required this.categoryText,
    required this.onFocus,
    required this.onDirections,
    required this.onToggleFavorite,
  });

  final bool poiLoading;
  final bool routeLoading;
  final Poi? selectedPoi;
  final bool isFavorite;
  final bool routeActive;
  final Widget routeSummary;
  final bool showRouteSummaryGap;
  final String? routeError;
  final String Function(Poi poi) distanceLabel;
  final String Function(String category) categoryText;
  final ValueChanged<Poi> onFocus;
  final VoidCallback onDirections;
  final VoidCallback onToggleFavorite;

  bool get _hasRealPoi => selectedPoi != null && selectedPoi!.category != 'custom';

  String? _scheduleLabel(BuildContext context, Poi poi) {
    final raw = poi.scheduleStatus?.trim();
    if (raw == null || raw.isEmpty) return null;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final normalized = raw.toLowerCase();
    if (normalized == 'open' || normalized == 'opened' || normalized == 'true') {
      return isRu ? 'Открыто' : 'Open';
    }
    if (normalized == 'closed' || normalized == 'false') {
      return isRu ? 'Закрыто' : 'Closed';
    }
    return raw;
  }

  String _reviewsLabel(BuildContext context, int count) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return isRu ? '$count отзывов' : '$count reviews';
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final chipColor = color ?? _MapScreenState._base;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chipColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(Poi poi) {
    final photoUrl = poi.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty || !_hasRealPoi) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          photoUrl,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poi = selectedPoi;
    final scheduleLabel = poi == null ? null : _scheduleLabel(context, poi);

    return Positioned(
      left: 12,
      right: 12,
      bottom: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.34,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _MapScreenState._base.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: _MapScreenState._base.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (poiLoading || routeLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (poi != null) _thumbnail(poi),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poi == null ? context.l10n.tapMarkerOrAdd : poi.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _MapScreenState._base,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          if (poi != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              poi.address ?? poi.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _MapScreenState._base.withOpacity(0.66),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 7,
                              runSpacing: 5,
                              children: [
                                Text(
                                  distanceLabel(poi),
                                  style: TextStyle(
                                    color: _MapScreenState._base.withOpacity(0.78),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (poi.rating != null)
                                  _infoChip(
                                    icon: Icons.star_rounded,
                                    text: poi.reviewsCount == null
                                        ? poi.rating!.toStringAsFixed(1)
                                        : '${poi.rating!.toStringAsFixed(1)} · ${_reviewsLabel(context, poi.reviewsCount!)}',
                                    color: _MapScreenState._accent,
                                  ),
                                if (scheduleLabel != null)
                                  _infoChip(
                                    icon: Icons.access_time_rounded,
                                    text: scheduleLabel,
                                    color: scheduleLabel.toLowerCase().contains('закры') ||
                                            scheduleLabel.toLowerCase().contains('closed')
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                  ),
                              ],
                            ),
                            if (poi.category != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                categoryText(poi.category!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _MapScreenState._base.withOpacity(0.58),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (poi.description.trim().isNotEmpty &&
                                poi.description.trim() !=
                                    (poi.address ?? '').trim() &&
                                poi.photoUrl != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                poi.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _MapScreenState._base.withOpacity(0.66),
                                  fontSize: 11.5,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (poi != null) ...[
                  const SizedBox(height: 8),
                  routeSummary,
                  if (!routeActive) ...[
                    if (showRouteSummaryGap) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onFocus(poi),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.my_location_outlined, size: 17),
                            label: Text(
                              context.l10n.openOnMap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onDirections,
                            style: FilledButton.styleFrom(
                              backgroundColor: _MapScreenState._accent,
                              foregroundColor: _MapScreenState._base,
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.route, size: 17),
                            label: Text(context.l10n.directions),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: poi.id <= 0 ? null : onToggleFavorite,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_outlined,
                            color: isFavorite
                                ? _MapScreenState._accent
                                : _MapScreenState._base,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (routeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.errorLabel}: ${AppErrorText.fromMessage(context, routeError!)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
