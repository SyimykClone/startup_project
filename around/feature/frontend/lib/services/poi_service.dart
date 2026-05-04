import '../core/network/api_client.dart';
import '../models/poi.dart';
import '../mock/mock_poi.dart';

class PoiService {
  final ApiClient api;

  final bool useMock;

  PoiService(this.api, {this.useMock = true});

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

    final res = await api.dio.get(
      '/api/google/places/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'place_type': placeType,
        'radius_m': radiusM,
        'language': language,
      },
    );
    final data = res.data as List;
    return data.map((e) {
      final json = (e as Map).cast<String, dynamic>();
      return Poi.fromJson({
        ...json,
        'id': -json['place_id'].toString().hashCode.abs(),
        'description': json['address'] ?? json['category'] ?? '',
      });
    }).toList();
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
    return data.map((e) {
      final json = (e as Map).cast<String, dynamic>();
      return Poi.fromJson({
        ...json,
        'id': -json['place_id'].toString().hashCode.abs(),
        'category': 'google_place',
        'description': json['address'] ?? '',
      });
    }).toList();
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
    return Poi.fromJson({
      ...json,
      'id': -json['place_id'].toString().hashCode.abs(),
      'description': json['address'] ?? json['types']?.toString() ?? '',
    });
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
