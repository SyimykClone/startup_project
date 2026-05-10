part of 'map_screen.dart';

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.title,
    required this.distanceLabel,
    required this.timeLabel,
    required this.modeLabel,
    required this.distance,
    required this.duration,
    required this.mode,
  });

  final String title;
  final String distanceLabel;
  final String timeLabel;
  final String modeLabel;
  final String distance;
  final String duration;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _MapScreenState._base,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route,
                color: _MapScreenState._accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RouteMetric(label: distanceLabel, value: distance),
              ),
              Expanded(
                child: _RouteMetric(label: timeLabel, value: duration),
              ),
              Expanded(
                child: _RouteMetric(label: modeLabel, value: mode),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RouteHistorySheet extends StatelessWidget {
  const _RouteHistorySheet({
    required this.title,
    required this.emptyText,
    required this.loading,
    required this.history,
    required this.modeText,
    required this.onSelected,
  });

  final String title;
  final String emptyText;
  final bool loading;
  final List<RouteHistoryItem> history;
  final String Function(String mode) modeText;
  final ValueChanged<RouteHistoryItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(title),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(child: Text(emptyText)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = history[index];
                    final distance =
                        '${(item.distanceM / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
                    final minutes =
                        '${(item.durationS / 60).toStringAsFixed(0)} ${context.l10n.minUnit}';
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _MapScreenState._base.withOpacity(0.12),
                        ),
                      ),
                      leading: const Icon(
                        Icons.history,
                        color: _MapScreenState._base,
                      ),
                      title: Text(
                        item.destinationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${modeText(item.profile)} - $distance - $minutes',
                      ),
                      onTap: () => onSelected(item),
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

class _RoutesSheet extends StatelessWidget {
  const _RoutesSheet({
    required this.destinations,
    required this.modeText,
    required this.onAdd,
    required this.onEdit,
    required this.onBuild,
  });

  final List<_DestinationItem> destinations;
  final String Function(String mode) modeText;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onBuild;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _SheetTitle(context.l10n.destinations)),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (destinations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(child: Text(context.l10n.noDestinations)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = destinations[i];
                    final eta = d.durationS == null
                        ? '--'
                        : '${(d.durationS! / 60).toStringAsFixed(0)} ${context.l10n.minUnit}';
                    final dist = d.distanceM == null
                        ? '--'
                        : '${(d.distanceM! / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _MapScreenState._base.withOpacity(0.12),
                        ),
                      ),
                      leading: const Icon(
                        Icons.route,
                        color: _MapScreenState._base,
                      ),
                      title: Text(
                        d.poi.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${d.mode == null ? context.l10n.selectMode : modeText(d.mode!)} - $dist - $eta',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(i),
                      ),
                      onTap: () {
                        if (d.mode == null) {
                          onEdit(i);
                        } else {
                          onBuild(i);
                        }
                      },
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

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _MapScreenState._base,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
