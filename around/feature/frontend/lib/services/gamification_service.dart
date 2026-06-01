import '../core/network/api_client.dart';
import '../models/gamification.dart';

class GamificationService {
  final ApiClient _api;

  GamificationService(this._api);

  Future<GamificationProgress> fetchMe() async {
    final response = await _api.dio.get('/api/gamification/me');
    final json = response.data as Map<String, dynamic>;
    return GamificationProgress.fromJson(Map<String, dynamic>.from(json));
  }
}
