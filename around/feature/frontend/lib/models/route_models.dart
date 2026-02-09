class RouteRequest {
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String profile;

  RouteRequest({
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    this.profile = 'walking',
  });

  Map<String, dynamic> toJson() => {
        "from_lat": fromLat,
        "from_lng": fromLng,
        "to_lat": toLat,
        "to_lng": toLng,
        "profile": profile,
      };
}

class RouteResponse {
  final double distanceM;
  final double durationS;
  final Map<String, dynamic> geometry;

  RouteResponse({
    required this.distanceM,
    required this.durationS,
    required this.geometry,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      distanceM: (json['distance_m'] as num).toDouble(),
      durationS: (json['duration_s'] as num).toDouble(),
      geometry: (json['geometry'] as Map).cast<String, dynamic>(),
    );
  }
}
