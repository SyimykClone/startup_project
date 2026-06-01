import 'dart:math';

import '../core/network/api_client.dart';
import '../models/poi.dart';
import '../models/route_models.dart';

class RouteService {
  final ApiClient api;

  final bool useMock;

  RouteService(this.api, {this.useMock = true});

  double _distanceM(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthR = 6371000.0;
    final dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
    final dLon = (lon2 - lon1) * (3.141592653589793 / 180.0);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * (3.141592653589793 / 180.0)) *
            cos(lat2 * (3.141592653589793 / 180.0)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthR * c;
  }

  List<double>? _pointToCoordinate(dynamic value) {
    if (value is List && value.length >= 2 && value[0] is num && value[1] is num) {
      return [(value[0] as num).toDouble(), (value[1] as num).toDouble()];
    }
    if (value is Map) {
      final lng = value['lng'] ?? value['lon'] ?? value['longitude'] ?? value['x'];
      final lat = value['lat'] ?? value['latitude'] ?? value['y'];
      if (lng is num && lat is num) {
        return [lng.toDouble(), lat.toDouble()];
      }
    }
    return null;
  }

  List<List<double>> _extractCoordinatesDeep(dynamic value) {
    if (value is List) {
      final parsed = value.map(_pointToCoordinate).whereType<List<double>>().toList();
      if (parsed.length >= 2) return parsed;
      for (final item in value) {
        final nested = _extractCoordinatesDeep(item);
        if (nested.length >= 2) return nested;
      }
      return const [];
    }

    if (value is Map) {
      const preferredKeys = [
        'coordinates',
        'points',
        'path',
        'polyline',
        'geometry',
        'selection',
        'outcoming_path',
        'walking_path',
        'result',
        'routes',
        'items',
      ];
      for (final key in preferredKeys) {
        if (!value.containsKey(key)) continue;
        final nested = _extractCoordinatesDeep(value[key]);
        if (nested.length >= 2) return nested;
      }
      for (final entry in value.entries) {
        if (preferredKeys.contains(entry.key)) continue;
        final nested = _extractCoordinatesDeep(entry.value);
        if (nested.length >= 2) return nested;
      }
    }

    return const [];
  }

  String _transportForProfile(String profile) {
    switch (profile) {
      case 'walking':
        return 'pedestrian';
      case 'cycling':
        return 'bicycle';
      case 'transit':
      case 'driving':
      default:
        return 'car';
    }
  }

  Future<RouteResponse> buildRoute(RouteRequest req) async {
    if (useMock) {
      final geometry = {
        "type": "LineString",
        "coordinates": [
          [req.fromLng, req.fromLat],
          [req.toLng, req.toLat],
        ]
      };

      return RouteResponse(
        distanceM: 0,
        durationS: 0,
        geometry: geometry,
      );
    }

    final res = await api.dio.post('/api/2gis/directions', data: req.toJson());
    return RouteResponse.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<RouteResponse> buildRoutePublic(RouteRequest req) async {
    if (useMock) {
      return RouteResponse(
        distanceM: _distanceM(req.fromLat, req.fromLng, req.toLat, req.toLng),
        durationS: 0,
        geometry: {
          'type': 'LineString',
          'coordinates': [
            [req.fromLng, req.fromLat],
            [req.toLng, req.toLat],
          ],
          'fallback': true,
        },
      );
    }

    final res = await api.dio.get(
      '/api/2gis/directions',
      queryParameters: {
        'from_lat': req.fromLat,
        'from_lng': req.fromLng,
        'to_lat': req.toLat,
        'to_lng': req.toLng,
        'transport': _transportForProfile(req.profile),
        'locale': 'ru',
      },
    );

    final data = (res.data as Map).cast<String, dynamic>();
    final raw = data['raw_2gis'];
    final coordinates = _extractCoordinatesDeep(raw);
    if (coordinates.length < 2) {
      throw StateError('Could not extract route geometry from public directions');
    }

    final distance = _distanceM(req.fromLat, req.fromLng, req.toLat, req.toLng);
    final speed = req.profile == 'walking' ? 1.25 : 8.0;

    return RouteResponse(
      distanceM: distance,
      durationS: distance / speed,
      geometry: {
        'type': 'LineString',
        'coordinates': coordinates,
        'provider': '2gis_public',
        'fallback': false,
      },
    );
  }

  Future<RouteResponse> buildTourRoute(List<Poi> stops) async {
    if (useMock || stops.length < 2) {
      return RouteResponse(
        distanceM: 0,
        durationS: 0,
        geometry: {
          'type': 'LineString',
          'coordinates': stops.map((p) => [p.longitude, p.latitude]).toList(),
        },
      );
    }

    final res = await api.dio.post(
      '/api/2gis/tour-route',
      data: {
        'profile': 'driving',
        'points': stops
            .map((poi) => {'lat': poi.latitude, 'lng': poi.longitude})
            .toList(),
      },
    );
    return RouteResponse.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<RouteHistoryItem>> fetchHistory({int limit = 10}) async {
    if (useMock) return [];

    final res = await api.dio.get(
      '/api/2gis/directions/history',
      queryParameters: {'limit': limit},
    );
    final data = res.data as List;
    return data
        .map((e) => RouteHistoryItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
