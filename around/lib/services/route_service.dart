import '../core/network/api_client.dart';
import '../models/route_models.dart';

class RouteService {
  final ApiClient api;

  final bool useMock;

  RouteService(this.api, {this.useMock = true});

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

    final res = await api.dio.post('/api/route', data: req.toJson());
    return RouteResponse.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
