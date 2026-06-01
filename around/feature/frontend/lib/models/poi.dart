class Poi {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? category;
  final String? googlePlaceId;
  final String? provider;
  final String? providerPlaceId;
  final String? fullName;
  final double? rating;
  final String? address;
  final String? fullAddress;
  final String? addressComment;
  final String? photoName;
  final String? photoUrl;
  final List<String> photoUrls;
  final String? phone;
  final List<String> phones;
  final String? email;
  final List<String> emails;
  final String? website;
  final List<String> websites;
  final String? scheduleStatus;
  final int? reviewsCount;
  final List<String> rubricNames;
  final Map<String, dynamic>? raw2Gis;
  final bool arEnabled;
  final String? arModelAsset;
  final String? arTitle;
  final String? arDescription;
  final int arRadiusM;
  final double? arDistanceM;
  final bool? arWithinRadius;

  Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.category,
    this.googlePlaceId,
    this.provider,
    this.providerPlaceId,
    this.fullName,
    this.rating,
    this.address,
    this.fullAddress,
    this.addressComment,
    this.photoName,
    this.photoUrl,
    this.photoUrls = const [],
    this.phone,
    this.phones = const [],
    this.email,
    this.emails = const [],
    this.website,
    this.websites = const [],
    this.scheduleStatus,
    this.reviewsCount,
    this.rubricNames = const [],
    this.raw2Gis,
    this.arEnabled = false,
    this.arModelAsset,
    this.arTitle,
    this.arDescription,
    this.arRadiusM = 120,
    this.arDistanceM,
    this.arWithinRadius,
  });

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? json['address'] ?? '').toString(),
      latitude: ((json['latitude'] ?? json['lat']) as num).toDouble(),
      longitude: ((json['longitude'] ?? json['lng']) as num).toDouble(),
      category: json['category'] as String?,
      googlePlaceId: (json['google_place_id'] ?? json['place_id']) as String?,
      provider: json['provider'] as String?,
      providerPlaceId: json['provider_place_id'] as String?,
      fullName: json['full_name'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      address: json['address'] as String?,
      fullAddress: json['full_address'] as String?,
      addressComment: json['address_comment'] as String?,
      photoName: json['photo_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      photoUrls: _stringList(json['photo_urls']),
      phone: json['phone'] as String?,
      phones: _stringList(json['phones']),
      email: json['email'] as String?,
      emails: _stringList(json['emails']),
      website: json['website'] as String?,
      websites: _stringList(json['websites']),
      scheduleStatus: json['schedule_status'] as String?,
      reviewsCount: (json['reviews_count'] as num?)?.toInt(),
      rubricNames: _stringList(json['rubric_names']),
      raw2Gis: (json['raw_2gis'] as Map?)?.cast<String, dynamic>(),
      arEnabled: json['ar_enabled'] == true,
      arModelAsset: json['ar_model_asset'] as String?,
      arTitle: json['ar_title'] as String?,
      arDescription: json['ar_description'] as String?,
      arRadiusM: (json['ar_radius_m'] as num?)?.toInt() ?? 120,
      arDistanceM: (json['distance_m'] as num?)?.toDouble(),
      arWithinRadius: json['within_radius'] as bool?,
    );
  }
}
