class Tour {
  final int id;
  final int businessUserId;
  final String title;
  final String description;
  final int durationDays;
  final double price;
  final double distanceKm;
  final int stopsCount;
  final String difficulty;
  final bool isPublished;

  Tour({
    required this.id,
    required this.businessUserId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.price,
    required this.distanceKm,
    required this.stopsCount,
    required this.difficulty,
    required this.isPublished,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'] as int,
      businessUserId: json['business_user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      durationDays: json['duration_days'] as int,
      price: (json['price'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      stopsCount: json['stops_count'] as int,
      difficulty: json['difficulty'] as String,
      isPublished: json['is_published'] as bool,
    );
  }
}
