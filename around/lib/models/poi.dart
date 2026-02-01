class Poi {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? category;

  Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String?,
    );
  }
}
