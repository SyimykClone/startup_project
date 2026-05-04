class RouteRequest {
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String profile;
  final String? destinationName;

  RouteRequest({
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    this.profile = 'walking',
    this.destinationName,
  });

  Map<String, dynamic> toJson() => {
        "from_lat": fromLat,
        "from_lng": fromLng,
        "to_lat": toLat,
        "to_lng": toLng,
        "profile": profile,
        if (destinationName != null) "destination_name": destinationName,
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

class RouteHistoryItem {
  final int id;
  final String destinationName;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String profile;
  final double distanceM;
  final double durationS;
  final DateTime createdAt;

  RouteHistoryItem({
    required this.id,
    required this.destinationName,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.profile,
    required this.distanceM,
    required this.durationS,
    required this.createdAt,
  });

  factory RouteHistoryItem.fromJson(Map<String, dynamic> json) {
    return RouteHistoryItem(
      id: (json['id'] as num).toInt(),
      destinationName: (json['destination_name'] ?? '').toString(),
      fromLat: (json['from_lat'] as num).toDouble(),
      fromLng: (json['from_lng'] as num).toDouble(),
      toLat: (json['to_lat'] as num).toDouble(),
      toLng: (json['to_lng'] as num).toDouble(),
      profile: (json['profile'] ?? 'walking').toString(),
      distanceM: (json['distance_m'] as num).toDouble(),
      durationS: (json['duration_s'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
