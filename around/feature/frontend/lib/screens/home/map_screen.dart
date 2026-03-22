import 'package:around/state/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../models/poi.dart';
import '../../models/route_models.dart';
import '../../services/location_service.dart';
import '../../services/poi_service.dart';
import '../../services/route_service.dart';
import '../../state/poi_state.dart';
import '../../state/route_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);

  GoogleMapController? _map;

  late PoiService _poiService;
  late RouteService _routeService;
  final _location = LocationService();

  LatLng? _userPos;
  Poi? _selectedPoi;

  final Map<MarkerId, Poi> _poiByMarkerId = {};
  final Set<int> _favoritePoiIds = <int>{};
  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};

  bool _servicesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_servicesInitialized) return;
    _servicesInitialized = true;

    final cfg = context.read<AppConfig>();
    final token = context.read<AuthState>().token;
    _poiService = PoiService(
      ApiClient(cfg.apiBaseUrl, token: token),
      useMock: cfg.useMock,
    );
    _routeService = RouteService(
      ApiClient(cfg.apiBaseUrl, token: token),
      useMock: cfg.useMock,
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _map = controller;
    await _loadUserLocation();
    await _loadPoiAndDrawMarkers();
    await _loadFavorites();

    if (_selectedPoi != null && _userPos != null) {
      await _buildAndDrawRoute(_selectedPoi!);
    }
  }

  Future<void> _loadUserLocation() async {
    final pos = await _location.getCurrentPosition();
    _userPos = LatLng(pos.latitude, pos.longitude);

    await _map?.animateCamera(CameraUpdate.newLatLngZoom(_userPos!, 14));
  }

  Future<void> _openPoiPicker() async {
    final result = await Navigator.pushNamed(context, Routes.poiList);
    if (!mounted || result is! Poi) return;

    setState(() => _selectedPoi = result);
    if (_userPos != null) {
      await _buildAndDrawRoute(result);
    }
  }

  Future<void> _loadPoiAndDrawMarkers() async {
    final poiState = context.read<PoiState>();
    poiState.setLoading(true);
    poiState.setError(null);

    try {
      final list = await _poiService.fetchPoiList();
      poiState.setPoi(list);
      _drawPoiMarkers(list);
    } catch (e) {
      poiState.setError(e.toString());
    } finally {
      poiState.setLoading(false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _poiService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favoritePoiIds
          ..clear()
          ..addAll(favorites.map((p) => p.id));
      });
    } catch (_) {
      // keep map usable even if favorites endpoint failed
    }
  }

  void _drawPoiMarkers(List<Poi> list) {
    final markers = <Marker>{};
    _poiByMarkerId.clear();

    for (final p in list) {
      final markerId = MarkerId('poi_${p.id}');
      _poiByMarkerId[markerId] = p;
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(title: p.name),
          onTap: () async {
            setState(() => _selectedPoi = p);
            if (_userPos != null) {
              await _buildAndDrawRoute(p);
            }
          },
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  Future<void> _buildAndDrawRoute(Poi poi) async {
    final routeState = context.read<RouteState>();
    if (_userPos == null) {
      routeState.fail('User location not found');
      return;
    }

    routeState.start();

    try {
      final req = RouteRequest(
        fromLat: _userPos!.latitude,
        fromLng: _userPos!.longitude,
        toLat: poi.latitude,
        toLng: poi.longitude,
        profile: 'walking',
      );

      final resp = await _routeService.buildRoute(req);
      routeState.setRoute(resp);
      await _poiService.markVisited(poi.id);
      _drawRoute(resp);
    } catch (e) {
      var msg = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          msg = data['detail'].toString();
        } else if (data is String && data.isNotEmpty) {
          msg = data;
        } else if (e.message != null && e.message!.isNotEmpty) {
          msg = e.message!;
        } else if (e.response?.statusCode != null) {
          msg = 'Request failed (${e.response!.statusCode})';
        }
      }
      routeState.fail(msg);
    }
  }

  void _drawRoute(RouteResponse resp) {
    final coords = (resp.geometry['coordinates'] as List)
        .map((c) => c as List)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: coords,
          width: 5,
          color: _base,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final poiState = context.watch<PoiState>();
    final routeState = context.watch<RouteState>();
    final isFavorite =
        _selectedPoi != null && _favoritePoiIds.contains(_selectedPoi!.id);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _base.withOpacity(0.12)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14151E3F),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 18, color: _base),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'My location',
                          style: TextStyle(
                            color: _base,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _openPoiPicker,
                        color: _base,
                        icon: const Icon(Icons.list),
                      ),
                    ],
                  ),
                  Divider(height: 8, color: _base.withOpacity(0.14)),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 18, color: _base),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _openPoiPicker,
                          child: Text(
                            _selectedPoi == null
                                ? 'Where to?'
                                : _selectedPoi!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _selectedPoi == null
                                  ? _base.withOpacity(0.6)
                                  : _base,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(42.828912, 75.289289),
                    zoom: 12,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: _onMapCreated,
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _base.withOpacity(0.12)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F151E3F),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (poiState.loading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedPoi == null
                                    ? 'Select destination point'
                                    : 'Selected: ${_selectedPoi!.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _base,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: _base,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed:
                                  (_selectedPoi == null || routeState.loading)
                                  ? null
                                  : () => _buildAndDrawRoute(_selectedPoi!),
                              child: const Text('Build route'),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: _selectedPoi == null
                                  ? null
                                  : () async {
                                      final poi = _selectedPoi!;
                                      try {
                                        if (_favoritePoiIds.contains(poi.id)) {
                                          await _poiService.removeFavorite(
                                            poi.id,
                                          );
                                          if (!mounted) return;
                                          setState(
                                            () =>
                                                _favoritePoiIds.remove(poi.id),
                                          );
                                        } else {
                                          await _poiService.addFavorite(poi.id);
                                          if (!mounted) return;
                                          setState(
                                            () => _favoritePoiIds.add(poi.id),
                                          );
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Favorite action failed: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border_outlined,
                                color: isFavorite ? _accent : _base,
                              ),
                            ),
                          ],
                        ),
                        if (routeState.route != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Distance: ${routeState.route!.distanceM.toStringAsFixed(0)} m, '
                            'Time: ${(routeState.route!.durationS / 60).toStringAsFixed(1)} min',
                            style: const TextStyle(
                              color: _base,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (routeState.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${routeState.error}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
