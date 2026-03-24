import 'package:flutter/material.dart';

class ToursScreen extends StatelessWidget {
  const ToursScreen({super.key});

  static const _base = Color(0xFF151E3F);
  static const _accent = Color(0xFFFAA916);

  static const _mockTours = <_TourItem>[
    _TourItem(
      title: 'Historic Center Walk',
      duration: '1h 20m',
      distance: '4.2 km',
      stops: 6,
      level: 'Easy',
    ),
    _TourItem(
      title: 'Parks and Riverside',
      duration: '2h 05m',
      distance: '6.8 km',
      stops: 8,
      level: 'Medium',
    ),
    _TourItem(
      title: 'Architecture Route',
      duration: '2h 40m',
      distance: '9.1 km',
      stops: 10,
      level: 'Extended',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tours',
              style: TextStyle(
                color: _base,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ready-made routes (mock data)',
              style: TextStyle(color: _base.withOpacity(0.7)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: _mockTours.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final tour = _mockTours[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _base.withOpacity(0.14)),
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
                                  color: _base,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3D9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tour.level,
                                style: const TextStyle(
                                  color: _base,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(icon: Icons.schedule_outlined, text: tour.duration),
                            _InfoChip(icon: Icons.route_outlined, text: tour.distance),
                            _InfoChip(icon: Icons.place_outlined, text: '${tour.stops} stops'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text('Open tour'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _base,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _TourItem {
  const _TourItem({
    required this.title,
    required this.duration,
    required this.distance,
    required this.stops,
    required this.level,
  });

  final String title;
  final String duration;
  final String distance;
  final int stops;
  final String level;
}
