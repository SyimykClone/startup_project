import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n.dart';
import '../../models/poi.dart';
import '../../state/route_state.dart';
import '../../core/router/app_router.dart';
import '../../utils/app_error_text.dart';

class PoiDetailScreen extends StatelessWidget {
  final Poi poi;
  const PoiDetailScreen({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF062244);
    const accent = Color(0xFFFAA916);
    final routeState = context.watch<RouteState>();
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final coordinatesLabel = locale == 'ru' ? 'Координаты' : 'Coordinates';
    final routeErrorLabel = locale == 'ru' ? 'Ошибка маршрута' : 'Route error';
    final addressLabel = locale == 'ru' ? 'Адрес' : 'Address';
    final contactsLabel = locale == 'ru' ? 'Контакты' : 'Contacts';
    final scheduleLabel = locale == 'ru' ? 'График' : 'Schedule';
    final ratingLabel = locale == 'ru' ? 'Рейтинг' : 'Rating';
    final sourceLabel = locale == 'ru' ? 'Источник' : 'Source';
    final fullAddress = poi.fullAddress ?? poi.address;
    final contacts = [
      poi.phone,
      ...poi.phones,
      poi.website,
      ...poi.websites,
      poi.email,
      ...poi.emails,
    ]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final categories = poi.rubricNames.isNotEmpty
        ? poi.rubricNames
        : [if (poi.category != null) poi.category!];

    return Scaffold(
      backgroundColor: base,
      appBar: AppBar(
        title: Text(poi.name),
        backgroundColor: base,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (poi.photoUrl != null || poi.photoUrls.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          poi.photoUrl ?? poi.photoUrls.first,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      poi.description.trim().isEmpty
                          ? poi.name
                          : poi.description,
                      style: const TextStyle(
                        color: base,
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (fullAddress != null && fullAddress.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_outlined,
                        label: addressLabel,
                        value: fullAddress,
                      ),
                    if (poi.rating != null)
                      _InfoRow(
                        icon: Icons.star_rounded,
                        label: ratingLabel,
                        value: poi.reviewsCount == null
                            ? poi.rating!.toStringAsFixed(1)
                            : '${poi.rating!.toStringAsFixed(1)} · ${poi.reviewsCount} ${locale == 'ru' ? 'отзывов' : 'reviews'}',
                      ),
                    if (poi.scheduleStatus != null &&
                        poi.scheduleStatus!.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: scheduleLabel,
                        value: poi.scheduleStatus!,
                      ),
                    if (contacts.isNotEmpty)
                      _InfoRow(
                        icon: Icons.call_outlined,
                        label: contactsLabel,
                        value: contacts.take(3).join('\n'),
                      ),
                    if (categories.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.take(4).map((category) {
                          return Chip(
                            label: Text(category),
                            backgroundColor: const Color(0xFFF4F6FC),
                            side: BorderSide(color: base.withOpacity(0.08)),
                          );
                        }).toList(),
                      ),
                    if (poi.provider != null || poi.providerPlaceId != null)
                      _InfoRow(
                        icon: Icons.dataset_outlined,
                        label: sourceLabel,
                        value: [
                          if (poi.provider != null) poi.provider!,
                          if (poi.providerPlaceId != null) poi.providerPlaceId!,
                        ].join(' · '),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$coordinatesLabel: '
                            '${poi.latitude.toStringAsFixed(5)}, '
                            '${poi.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              color: base.withOpacity(0.68),
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (routeState.loading) const LinearProgressIndicator(),
              if (routeState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$routeErrorLabel: '
                    '${AppErrorText.fromMessage(context, routeState.error!)}',
                    style: const TextStyle(
                      color: Color(0xFF7A1F1F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.map,
                      arguments: AppShellArgs(initialIndex: 2, initialPoi: poi),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3E7),
                    foregroundColor: accent,
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(l10n.openOnMap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF062244);
    const accent = Color(0xFFFAA916);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: base.withOpacity(0.48),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: base.withOpacity(0.76),
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
