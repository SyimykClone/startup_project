part of 'map_screen.dart';

class _NearbyFiltersSheet extends StatelessWidget {
  const _NearbyFiltersSheet({
    required this.title,
    required this.categories,
    required this.selectedType,
    required this.loading,
    required this.onSelected,
  });

  final String title;
  final List<_NearbyCategory> categories;
  final String? selectedType;
  final bool loading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetTitle(title),
              const SizedBox(height: 6),
              Text(
                isRu
                    ? 'Выберите, что показать на карте рядом с вами'
                    : 'Choose what to show near you on the map',
                style: TextStyle(
                  color: _MapScreenState._base.withOpacity(0.58),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.25,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = selectedType == category.type;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: loading ? null : () => onSelected(category.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _MapScreenState._base
                            : const Color(0xFFF5F7FC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? _MapScreenState._accent
                              : _MapScreenState._base.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: selected
                                  ? _MapScreenState._accent
                                  : _MapScreenState._accent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              selected ? Icons.check_rounded : category.icon,
                              size: 19,
                              color: _MapScreenState._base,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRu ? category.ruTitle : category.enTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : _MapScreenState._base,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isRu
                                      ? category.ruSubtitle
                                      : category.enSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white.withOpacity(0.68)
                                        : _MapScreenState._base.withOpacity(0.52),
                                    fontSize: 10,
                                    height: 1.05,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
