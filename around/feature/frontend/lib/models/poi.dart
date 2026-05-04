class Poi {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? category;
  final String? googlePlaceId;
  final double? rating;
  final String? address;

  Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.category,
    this.googlePlaceId,
    this.rating,
    this.address,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? json['address'] ?? '').toString(),
      latitude: ((json['latitude'] ?? json['lat']) as num).toDouble(),
      longitude: ((json['longitude'] ?? json['lng']) as num).toDouble(),
      category: json['category'] as String?,
      googlePlaceId: (json['google_place_id'] ?? json['place_id']) as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      address: json['address'] as String?,
    );
  }
}
