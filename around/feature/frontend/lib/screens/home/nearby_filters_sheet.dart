part of 'map_screen.dart';

class _NearbyFiltersSheet extends StatelessWidget {
  const _NearbyFiltersSheet({
    required this.title,
    required this.nearbyTypes,
    required this.selectedType,
    required this.loading,
    required this.typeText,
    required this.onSelected,
  });

  final String title;
  final List<String> nearbyTypes;
  final String? selectedType;
  final bool loading;
  final String Function(String type) typeText;
  final ValueChanged<String> onSelected;

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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nearbyTypes.map((type) {
                return ActionChip(
                  avatar: Icon(
                    selectedType == type ? Icons.check : Icons.travel_explore,
                    size: 18,
                  ),
                  label: Text(typeText(type)),
                  onPressed: loading ? null : () => onSelected(type),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
