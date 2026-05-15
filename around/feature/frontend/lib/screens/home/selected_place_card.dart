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

  @override
  Widget build(BuildContext context) {
    final poi = selectedPoi;

    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _MapScreenState._base.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (poiLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
            if (routeLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
            if (poi?.photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  poi!.photoUrl!,
                  width: double.infinity,
                  height: 128,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (poi != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          poi.address ?? poi.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _MapScreenState._base.withOpacity(0.68),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Text(
                              distanceLabel(poi),
                              style: TextStyle(
                                color:
                                    _MapScreenState._base.withOpacity(0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (poi.rating != null)
                              Text(
                                '* ${poi.rating!.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: _MapScreenState._accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        if (poi.category != null)
                          Text(
                            categoryText(poi.category!),
                            style: TextStyle(
                              color: _MapScreenState._base.withOpacity(0.58),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (poi.description.trim().isNotEmpty &&
                            poi.description.trim() !=
                                (poi.address ?? '').trim()) ...[
                          const SizedBox(height: 5),
                          Text(
                            poi.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _MapScreenState._base.withOpacity(0.7),
                              fontSize: 12,
                              height: 1.25,
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
              const SizedBox(height: 10),
              routeSummary,
              if (!routeActive) ...[
                if (showRouteSummaryGap) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onFocus(poi),
                        icon: const Icon(Icons.my_location_outlined, size: 18),
                        label: Text(context.l10n.openOnMap),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onDirections,
                        style: FilledButton.styleFrom(
                          backgroundColor: _MapScreenState._accent,
                          foregroundColor: _MapScreenState._base,
                        ),
                        icon: const Icon(Icons.route, size: 18),
                        label: Text(context.l10n.directions),
                      ),
                    ),
                    IconButton(
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
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
