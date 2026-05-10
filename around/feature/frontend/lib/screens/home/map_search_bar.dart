part of 'map_screen.dart';

class _MapTopPanel extends StatelessWidget {
  const _MapTopPanel({
    required this.searchCtrl,
    required this.searchQuery,
    required this.filteredPoi,
    required this.placesLoading,
    required this.foundLabel,
    required this.title,
    required this.searchHint,
    required this.nearbyTitle,
    required this.historyTitle,
    required this.onOpenNearby,
    required this.onOpenRoutes,
    required this.onOpenHistory,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFocusPoi,
  });

  final TextEditingController searchCtrl;
  final String searchQuery;
  final List<Poi> filteredPoi;
  final bool placesLoading;
  final String foundLabel;
  final String title;
  final String searchHint;
  final String nearbyTitle;
  final String historyTitle;
  final VoidCallback onOpenNearby;
  final VoidCallback onOpenRoutes;
  final VoidCallback onOpenHistory;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<Poi> onFocusPoi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _MapScreenState._base.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: nearbyTitle,
                  onPressed: onOpenNearby,
                  icon: const Icon(Icons.tune, color: _MapScreenState._base),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: context.l10n.destinations,
                  onPressed: onOpenRoutes,
                  icon: const Icon(
                    Icons.route_outlined,
                    color: _MapScreenState._base,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _MapScreenState._base,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (placesLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  tooltip: historyTitle,
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history, color: _MapScreenState._base),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                ),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close),
                      ),
                isDense: true,
              ),
              onChanged: onSearchChanged,
              onSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                foundLabel,
                style: TextStyle(
                  color: _MapScreenState._base.withOpacity(0.64),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (searchQuery.trim().isNotEmpty && filteredPoi.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredPoi.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final poi = filteredPoi[index];
                    return ActionChip(
                      avatar: const Icon(Icons.place_outlined, size: 18),
                      label: Text(
                        poi.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => onFocusPoi(poi),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
