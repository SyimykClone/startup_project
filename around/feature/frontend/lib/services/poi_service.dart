import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../mock/mock_poi.dart';
import '../models/poi.dart';

class PoiService {
  final ApiClient api;

  final bool useMock;

  PoiService(this.api, {this.useMock = true});

  bool _isCleanExternalPlace(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().toLowerCase();
    if (name.trim().isEmpty) return false;

    const blockedFragments = [
      '\u0441\u043e\u0441\u0430\u043b',
      '\u0441\u043e\u0441\u0430\u0442\u044c',
      '\u0445\u0443\u0439',
      '\u043f\u0438\u0437\u0434',
      '\u0435\u0431\u0430',
      '\u0451\u0431\u0430',
      '\u0431\u043b\u044f',
      '\u0441\u0443\u043a\u0430',
      'fuck',
      'shit',
    ];

    return !blockedFragments.any(name.contains);
  }

  String _nearbyFallbackQuery(String placeType) {
    switch (placeType) {
      case 'tourist_attraction':
        return '\u0434\u043e\u0441\u0442\u043e\u043f\u0440\u0438\u043c\u0435\u0447\u0430\u0442\u0435\u043b\u044c\u043d\u043e\u0441\u0442\u0438';
      case 'food':
        return '\u0435\u0434\u0430';
      case 'cafe':
        return '\u043a\u0430\u0444\u0435';
      case 'restaurant':
        return '\u0440\u0435\u0441\u0442\u043e\u0440\u0430\u043d';
      case 'lodging':
        return '\u043e\u0442\u0435\u043b\u0438';
      case 'museum':
        return '\u043c\u0443\u0437\u0435\u0438';
      case 'park':
        return '\u043f\u0430\u0440\u043a\u0438';
      case 'pharmacy':
        return '\u0430\u043f\u0442\u0435\u043a\u0430';
      case 'shop':
        return '\u043c\u0430\u0433\u0430\u0437\u0438\u043d';
      default:
        return placeType.replaceAll('_', ' ');
    }
  }

  double _distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusM = 6371000.0;
    final dLat = (toLat - fromLat) * math.pi / 180;
    final dLng = (toLng - fromLng) * math.pi / 180;
    final lat1 = fromLat * math.pi / 180;
    final lat2 = toLat * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<List<Poi>> fetchPoiList() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return mockPoiList;
    }

    final res = await api.dio.get('/api/poi');
    final data = res.data as List;
    return data
        .map((e) => Poi.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<Poi>> resolveTapWith2Gis({
    required double lat,
    required double lng,
    int radiusM = 120,
    String locale = 'ru_KG',
  }) async {
    if (useMock) return [];

    final res = await api.dio.get(
      '/api/2gis/resolve-tap',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius_m': radiusM,
        'locale': locale,
      },
    );
    final data = res.data as List;
    return data
        .map((e) => (e as Map).cast<String, dynamic>())
        .where(_isCleanExternalPlace)
        .map((json) {
          return Poi.fromJson({
            'id': -json['id'].toString().hashCode.abs(),
            'google_place_id': json['id']?.toString(),
            'name': json['name'],
            'description':
                json['description'] ?? json['address'] ?? json['category'] ?? '',
            'lat': json['lat'],
            'lng': json['lng'],
            'category': 'twogis_place',
            'address': json['address'],
            'rating': json['rating'],
            'photo_url': json['photo_url'],
          });
        })
        .toList();
  }

  Future<Poi> fetch2GisPlaceDetails({
    required String placeId,
    String locale = 'ru_KG',
  }) async {
    if (useMock) throw StateError('2GIS details are unavailable in mock mode');

    final res = await api.dio.get(
      '/api/2gis/places/$placeId',
      queryParameters: {'locale': locale},
    );
    final json = (res.data as Map).cast<String, dynamic>();
    return Poi.fromJson({
      'id': -placeId.hashCode.abs(),
      'google_place_id': placeId,
      'name': json['name'],
      'description': json['description'] ?? json['address'] ?? '',
      'lat': json['lat'],
      'lng': json['lng'],
      'category': 'twogis_place',
      'address': json['address'],
      'rating': json['rating'],
      'photo_url': json['photo_url'],
    });
  }

  Future<List<Poi>> fetch2GisNearbyPlaces({
    required double lat,
    required double lng,
    required String placeType,
    int radiusM = 2500,
    String locale = 'ru_KG',
  }) {
    return search2GisPlaces(
      query: _nearbyFallbackQuery(placeType),
      lat: lat,
      lng: lng,
      radiusM: radiusM,
      locale: locale,
    );
  }

  Future<List<Poi>> search2GisPlaces({
    required String query,
    double? lat,
    double? lng,
    int radiusM = 5000,
    String locale = 'ru_KG',
  }) async {
    if (useMock || query.trim().isEmpty) return [];

    final res = await api.dio.get(
      '/api/2gis/places/search',
      queryParameters: {
        'query': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radius_m': radiusM,
        'locale': locale,
        'page_size': 20,
      },
    );
    final data = res.data as List;
    return data
        .map((e) => (e as Map).cast<String, dynamic>())
        .where(_isCleanExternalPlace)
        .map((json) {
          return Poi.fromJson({
            'id': -json['id'].toString().hashCode.abs(),
            'google_place_id': json['id']?.toString(),
            'name': json['name'],
            'description':
                json['description'] ?? json['address'] ?? json['category'] ?? '',
            'lat': json['lat'],
            'lng': json['lng'],
            'category': 'twogis_place',
            'address': json['address'],
            'rating': json['rating'],
            'photo_url': json['photo_url'],
          });
        })
        .toList();
  }

  Future<Poi> fetchPoi(int id) async {
    if (useMock) {
      return mockPoiList.firstWhere((p) => p.id == id);
    }

    final res = await api.dio.get('/api/poi/$id');
    return Poi.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<Poi>> fetchFavorites() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 180));
      return mockPoiList.take(3).toList();
    }

    final res = await api.dio.get('/api/poi/favorites');
    final data = res.data as List;
    return data
        .map((e) => Poi.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> addFavorite(int poiId) async {
    if (useMock) return;
    await api.dio.post('/api/poi/favorites/$poiId');
  }

  Future<void> removeFavorite(int poiId) async {
    if (useMock) return;
    await api.dio.delete('/api/poi/favorites/$poiId');
  }

  Future<List<Poi>> fetchVisited() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 180));
      return mockPoiList.take(4).toList();
    }

    final res = await api.dio.get('/api/poi/visited');
    final data = res.data as List;
    return data
        .map((e) => Poi.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> markVisited(int poiId) async {
    if (useMock) return;
    await api.dio.post('/api/poi/visited/$poiId');
  }

  Future<Poi?> fetchNearbyArPoi({
    required double lat,
    required double lng,
    int maxDistanceM = 1000,
  }) async {
    if (useMock) {
      final arPoi = mockPoiList.where((poi) => poi.arEnabled).toList();
      return arPoi.isEmpty ? null : arPoi.first;
    }

    try {
      final res = await api.dio.get(
        '/api/poi/ar/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'max_distance_m': maxDistanceM,
        },
      );
      return Poi.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _findNearestArPoiFromList(
          lat: lat,
          lng: lng,
          maxDistanceM: maxDistanceM,
        );
      }
      rethrow;
    }
  }

  Future<Poi?> _findNearestArPoiFromList({
    required double lat,
    required double lng,
    required int maxDistanceM,
  }) async {
    final arPois = (await fetchPoiList())
        .where((poi) {
          final modelAsset = poi.arModelAsset?.trim() ?? '';
          return poi.arEnabled && modelAsset.isNotEmpty;
        })
        .toList();
    if (arPois.isEmpty) return null;

    arPois.sort((a, b) {
      final aDistance = _distanceMeters(
        fromLat: lat,
        fromLng: lng,
        toLat: a.latitude,
        toLng: a.longitude,
      );
      final bDistance = _distanceMeters(
        fromLat: lat,
        fromLng: lng,
        toLat: b.latitude,
        toLng: b.longitude,
      );
      return aDistance.compareTo(bDistance);
    });

    final nearest = arPois.first;
    final distance = _distanceMeters(
      fromLat: lat,
      fromLng: lng,
      toLat: nearest.latitude,
      toLng: nearest.longitude,
    );
    if (distance > maxDistanceM) return null;
    return nearest;
  }

  Future<Poi> createCustomPoiFromCoordinates({
    required double lat,
    required double lng,
    String language = 'ru',
  }) async {
    if (useMock) {
      return Poi(
        id: DateTime.now().millisecondsSinceEpoch,
        name: 'Pinned point',
        description: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        latitude: lat,
        longitude: lng,
        category: 'custom',
      );
    }

    final res = await api.dio.post(
      '/api/poi/custom/from-coordinates',
      data: {'lat': lat, 'lng': lng, 'language': language},
    );
    return Poi.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
