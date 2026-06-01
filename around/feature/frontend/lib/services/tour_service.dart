import '../core/network/api_client.dart';
import '../models/tour.dart';

class TourService {
  final ApiClient api;

  TourService(this.api);

  Future<List<Tour>> fetchAll() async {
    final res = await api.dio.get('/api/tours');
    final data = res.data as List;
    return data
        .map((e) => Tour.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<Tour>> fetchMine() async {
    final res = await api.dio.get('/api/tours/mine');
    final data = res.data as List;
    return data
        .map((e) => Tour.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Tour> create({
    required String title,
    required String description,
    required int durationDays,
    required double price,
    required double distanceKm,
    required int stopsCount,
    required String difficulty,
    required bool isPublished,
  }) async {
    final res = await api.dio.post(
      '/api/tours',
      data: {
        'title': title,
        'description': description,
        'duration_days': durationDays,
        'price': price,
        'distance_km': distanceKm,
        'stops_count': stopsCount,
        'difficulty': difficulty,
        'is_published': isPublished,
      },
    );
    return Tour.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<Tour> update(
    int id, {
    String? title,
    String? description,
    int? durationDays,
    double? price,
    double? distanceKm,
    int? stopsCount,
    String? difficulty,
    bool? isPublished,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (durationDays != null) data['duration_days'] = durationDays;
    if (price != null) data['price'] = price;
    if (distanceKm != null) data['distance_km'] = distanceKm;
    if (stopsCount != null) data['stops_count'] = stopsCount;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (isPublished != null) data['is_published'] = isPublished;
    final res = await api.dio.patch('/api/tours/$id', data: data);
    return Tour.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> delete(int id) async {
    await api.dio.delete('/api/tours/$id');
  }
}
