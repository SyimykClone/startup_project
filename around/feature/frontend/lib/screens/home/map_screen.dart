import 'package:around/state/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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

  MapboxMap? _map;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;

  late PoiService _poiService;
  late RouteService _routeService;
  final _location = LocationService();

  Position? _userPos;
  Poi? _selectedPoi;

  final Map<String, Poi> _poiByAnnotationId = {};
  bool _servicesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_servicesInitialized) return;
    _servicesInitialized = true;

    final cfg = context.read<AppConfig>();
    MapboxOptions.setAccessToken(cfg.mapboxToken);

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

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _map = mapboxMap;
    _pointManager = await _map!.annotations.createPointAnnotationManager();
    _polylineManager = await _map!.annotations
        .createPolylineAnnotationManager();

    _pointManager!.addOnPointAnnotationClickListener(
      _PoiClickListener((annotation) async {
        final poi = _poiByAnnotationId[annotation.id];
        if (poi == null) return;
        setState(() => _selectedPoi = poi);
        if (_userPos != null) {
          await _buildAndDrawRoute(poi);
        }
      }),
    );

    await _loadUserLocation();
    await _loadPoiAndDrawMarkers();

    if (_selectedPoi != null && _userPos != null) {
      await _buildAndDrawRoute(_selectedPoi!);
    }
  }

  Future<void> _loadUserLocation() async {
    final pos = await _location.getCurrentPosition();
    _userPos = Position(pos.longitude, pos.latitude);

    await _map?.flyTo(
      CameraOptions(center: Point(coordinates: _userPos!), zoom: 14),
      MapAnimationOptions(duration: 800),
    );
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
      await _drawPoiMarkers(list);
    } catch (e) {
      poiState.setError(e.toString());
    } finally {
      poiState.setLoading(false);
    }
  }

  Future<void> _drawPoiMarkers(List<Poi> list) async {
    if (_pointManager == null) return;

    await _pointManager!.deleteAll();
    _poiByAnnotationId.clear();

    for (final p in list) {
      final ann = await _pointManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(p.longitude, p.latitude)),
          textField: p.name,
          textOffset: [0, -2],
          textSize: 12,
        ),
      );
      _poiByAnnotationId[ann.id] = p;
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
        fromLat: _userPos!.lat.toDouble(),
        fromLng: _userPos!.lng.toDouble(),
        toLat: poi.latitude,
        toLng: poi.longitude,
        profile: 'walking',
      );

      final resp = await _routeService.buildRoute(req);
      routeState.setRoute(resp);
      await _drawRoute(resp);
    } catch (e) {
      String msg = e.toString();
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

  Future<void> _drawRoute(RouteResponse resp) async {
    if (_polylineManager == null) return;
    await _polylineManager!.deleteAll();

    final coords = (resp.geometry['coordinates'] as List)
        .map((c) => c as List)
        .map(
          (c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble()),
        )
        .toList();

    await _polylineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coords),
        lineWidth: 4.4,
        lineColor: _base.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poiState = context.watch<PoiState>();
    final routeState = context.watch<RouteState>();

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
                MapWidget(
                  key: const ValueKey('mapWidget'),
                  cameraOptions: CameraOptions(
                    center: Point(coordinates: Position(75.289289, 42.828912)),
                    zoom: 12,
                  ),
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

class _PoiClickListener extends OnPointAnnotationClickListener {
  final Future<void> Function(PointAnnotation) onClick;
  _PoiClickListener(this.onClick);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onClick(annotation);
  }
}
