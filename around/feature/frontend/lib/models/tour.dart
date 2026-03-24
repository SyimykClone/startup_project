class Tour {
  final int id;
  final int businessUserId;
  final String title;
  final String description;
  final int durationMin;
  final double distanceKm;

  Tour({
    required this.id,
    required this.businessUserId,
    required this.title,
    required this.description,
    required this.durationMin,
    required this.distanceKm,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'] as int,
      businessUserId: json['business_user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMin: json['duration_min'] as int,
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }
}
