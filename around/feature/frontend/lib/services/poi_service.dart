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

  Future<Poi> fetchPoi(int id) async {
    if (useMock) {
      return mockPoiList.firstWhere((p) => p.id == id);
    }

    final res = await api.dio.get('/api/poi/$id');
    return Poi.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
