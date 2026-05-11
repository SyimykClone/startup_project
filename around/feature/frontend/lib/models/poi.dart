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
  final String? photoName;
  final String? photoUrl;
  final bool arEnabled;
  final String? arModelAsset;
  final String? arTitle;
  final String? arDescription;
  final int arRadiusM;

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
    this.photoName,
    this.photoUrl,
    this.arEnabled = false,
    this.arModelAsset,
    this.arTitle,
    this.arDescription,
    this.arRadiusM = 120,
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
      photoName: json['photo_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      arEnabled: json['ar_enabled'] == true,
      arModelAsset: json['ar_model_asset'] as String?,
      arTitle: json['ar_title'] as String?,
      arDescription: json['ar_description'] as String?,
      arRadiusM: (json['ar_radius_m'] as num?)?.toInt() ?? 120,
    );
  }
}
