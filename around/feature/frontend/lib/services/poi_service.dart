import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../mock/mock_poi.dart';
import '../models/poi.dart';

class PoiService {
  final ApiClient api;

  final bool useMock;

  PoiService(this.api, {this.useMock = true});

  Map<String, dynamic> _withPhotoUrl(Map<String, dynamic> json) {
    final photoName = json['photo_name']?.toString();
    if (photoName == null || photoName.isEmpty) return json;
    final encoded = Uri.encodeQueryComponent(photoName);
    return {
      ...json,
      'photo_url':
          '${api.dio.options.baseUrl}/api/google/places/photo?photo_name=$encoded',
    };
  }

  bool _isCleanGooglePlace(Map<String, dynamic> json) {
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
        return 'tourist attractions';
      case 'cafe':
        return 'cafes';
      case 'lodging':
        return 'hotels';
      case 'museum':
        return 'museums';
      case 'park':
        return 'parks';
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

  Future<List<Poi>> fetchGoogleNearbyPlaces({
    required double lat,
    required double lng,
    required String placeType,
    int radiusM = 1500,
    String language = 'ru',
  }) async {
    if (useMock) return [];

    late final Response<dynamic> res;
    try {
      res = await api.dio.get(
        '/api/google/places/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'place_type': placeType,
          'radius_m': radiusM,
          'language': language,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      res = await api.dio.get(
        '/api/google/places/search',
        queryParameters: {
          'query': _nearbyFallbackQuery(placeType),
          'lat': lat,
          'lng': lng,
          'radius_m': radiusM,
          'language': language,
        },
      );
    }

    final data = res.data as List;
    return data
        .map((e) => (e as Map).cast<String, dynamic>())
        .where(_isCleanGooglePlace)
        .map((json) {
          return Poi.fromJson(_withPhotoUrl({
            ...json,
            'id': -json['place_id'].toString().hashCode.abs(),
            'description': json['address'] ?? json['category'] ?? '',
          }));
        })
        .toList();
  }

  Future<Poi?> findGooglePlaceNearCoordinates({
    required double lat,
    required double lng,
    int radiusM = 90,
    String language = 'ru',
  }) async {
    if (useMock) return null;

    const queries = [
      'store',
      'restaurant',
      'cafe',
      'pharmacy',
      'bank',
      'hotel',
      'museum',
      'park',
    ];

    final candidates = <Poi>[];
    for (final query in queries) {
      try {
        candidates.addAll(
          await searchGooglePlaces(
            query: query,
            lat: lat,
            lng: lng,
            radiusM: radiusM,
            language: language,
          ),
        );
      } catch (_) {}
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
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

    final nearest = candidates.first;
    final distance = _distanceMeters(
      fromLat: lat,
      fromLng: lng,
      toLat: nearest.latitude,
      toLng: nearest.longitude,
    );
    if (distance > radiusM) return null;
    return nearest;
  }

  Future<List<Poi>> resolveTapWith2Gis({
    required double lat,
    required double lng,
    int radiusM = 80,
    String locale = 'ru_RU',
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
        .where(_isCleanGooglePlace)
        .map((json) {
          return Poi.fromJson({
            'id': -json['id'].toString().hashCode.abs(),
            'name': json['name'],
            'description': json['address'] ?? json['category'] ?? '',
            'lat': json['lat'],
            'lng': json['lng'],
            'category': 'twogis_place',
            'address': json['address'],
          });
        })
        .toList();
  }

  Future<List<Poi>> searchGooglePlaces({
    required String query,
    double? lat,
    double? lng,
    int radiusM = 3000,
    String language = 'ru',
  }) async {
    if (useMock || query.trim().isEmpty) return [];

    final res = await api.dio.get(
      '/api/google/places/search',
      queryParameters: {
        'query': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radius_m': radiusM,
        'language': language,
      },
    );
    final data = res.data as List;
    return data
        .map((e) => (e as Map).cast<String, dynamic>())
        .where(_isCleanGooglePlace)
        .map((json) {
          return Poi.fromJson(_withPhotoUrl({
            ...json,
            'id': -json['place_id'].toString().hashCode.abs(),
            'category': 'google_place',
            'description': json['address'] ?? '',
          }));
        })
        .toList();
  }

  Future<Poi> fetchGooglePlaceDetails({
    required String placeId,
    String language = 'ru',
  }) async {
    final encodedPlaceId = Uri.encodeComponent(placeId);
    final res = await api.dio.get(
      '/api/google/places/details/$encodedPlaceId',
      queryParameters: {'language': language},
    );
    final json = (res.data as Map).cast<String, dynamic>();
    return Poi.fromJson(_withPhotoUrl({
      ...json,
      'id': -json['place_id'].toString().hashCode.abs(),
      'category': 'google_place',
      'description': json['address'] ?? json['types']?.toString() ?? '',
    }));
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
