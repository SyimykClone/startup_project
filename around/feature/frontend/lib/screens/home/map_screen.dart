import 'package:around/state/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_client.dart';
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

class _DestinationItem {
  _DestinationItem({required this.poi, required this.mode});

  final Poi poi;
  String mode;
  double? distanceM;
  double? durationS;
}

class _MapScreenState extends State<MapScreen> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);
  static const _modes = ['driving', 'transit', 'walking', 'cycling'];

  GoogleMapController? _map;

  late PoiService _poiService;
  late RouteService _routeService;
  final _location = LocationService();

  LatLng? _userPos;
  Poi? _selectedPoi;

  final Set<int> _favoritePoiIds = <int>{};
  final List<_DestinationItem> _destinations = [];
  int? _activeDestination;
  int _nextTempPoiId = -1;

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
  }

  Future<void> _loadUserLocation() async {
    final pos = await _location.getCurrentPosition();
    _userPos = LatLng(pos.latitude, pos.longitude);
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(_userPos!, 14));
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
      // keep map functional if favorites fail
    }
  }

  void _drawPoiMarkers(List<Poi> list) {
    final markers = <Marker>{};

    for (final p in list) {
      final markerId = MarkerId('poi_${p.id}');
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(title: p.name),
          onTap: () {
            setState(() => _selectedPoi = p);
          },
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    final l10n = context.l10n;
    final fallbackPoi = Poi(
      id: _nextTempPoiId--,
      name: l10n.pinnedPoint,
      description:
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      latitude: position.latitude,
      longitude: position.longitude,
      category: 'custom',
    );

    const tapMarkerId = MarkerId('tap_point');
    final nonTapMarkers = _markers.where((m) => m.markerId != tapMarkerId).toSet();
    nonTapMarkers.add(
      Marker(
        markerId: tapMarkerId,
        position: position,
        infoWindow: InfoWindow(title: l10n.pinnedPoint),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    setState(() {
      _markers = nonTapMarkers;
      _selectedPoi = fallbackPoi;
    });

    Poi customPoi = fallbackPoi;
    try {
      customPoi = await _poiService.createCustomPoiFromCoordinates(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotResolveAddress)),
        );
      }
    }

    if (!mounted) return;

    final refreshed = _markers.where((m) => m.markerId != tapMarkerId).toSet();
    refreshed.add(
      Marker(
        markerId: tapMarkerId,
        position: position,
        infoWindow: InfoWindow(title: customPoi.name, snippet: customPoi.description),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    final existingCustomIndex = _destinations.indexWhere((d) => d.poi.category == 'custom');
    final existingTempIndex = _destinations.indexWhere((d) => d.poi.id < 0);
    final replaceIndex = existingCustomIndex >= 0 ? existingCustomIndex : existingTempIndex;
    final targetIndex = replaceIndex >= 0 ? replaceIndex : _destinations.length;

    setState(() {
      _markers = refreshed;
      _selectedPoi = customPoi;
      if (replaceIndex >= 0) {
        _destinations[replaceIndex] = _DestinationItem(
          poi: customPoi,
          mode: _destinations[replaceIndex].mode,
        );
      } else {
        _destinations.add(_DestinationItem(poi: customPoi, mode: 'driving'));
      }
      _activeDestination = targetIndex;
    });

    await _buildAndDrawRoute(targetIndex);
  }

  Future<void> _showDestinationSheet({int? editIndex}) async {
    final poiState = context.read<PoiState>();
    if (poiState.poi.isEmpty) {
      await _loadPoiAndDrawMarkers();
    }
    if (!mounted || poiState.poi.isEmpty) return;

    Poi selectedPoi;
    String selectedMode;

    if (editIndex != null) {
      final d = _destinations[editIndex];
      selectedPoi = d.poi;
      selectedMode = d.mode;
    } else {
      selectedPoi = _selectedPoi ?? poiState.poi.first;
      selectedMode = 'driving';
    }

    final options = <Poi>[...poiState.poi];
    final hasSelectedInOptions = options.any((p) => p.id == selectedPoi.id);
    if (!hasSelectedInOptions) {
      options.insert(0, selectedPoi);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editIndex == null ? context.l10n.addDestination : context.l10n.editDestination,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _base,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedPoi.id,
                    items: options
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final picked = options.firstWhere((p) => p.id == v);
                      setModal(() => selectedPoi = picked);
                    },
                    decoration: InputDecoration(labelText: context.l10n.destination),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.travelMode,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _base),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _modes.map((mode) {
                      final selected = selectedMode == mode;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(mode),
                        onSelected: (_) => setModal(() => selectedMode = mode),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (editIndex == null) {
                              setState(() {
                                _destinations.add(_DestinationItem(poi: selectedPoi, mode: selectedMode));
                                _activeDestination = _destinations.length - 1;
                                _selectedPoi = selectedPoi;
                              });
                            } else {
                              setState(() {
                                _destinations[editIndex] = _DestinationItem(poi: selectedPoi, mode: selectedMode);
                                _activeDestination = editIndex;
                                _selectedPoi = selectedPoi;
                              });
                            }
                            Navigator.pop(context);
                            if (_activeDestination != null) {
                              _buildAndDrawRoute(_activeDestination!);
                            }
                          },
                          child: Text(editIndex == null ? context.l10n.add : context.l10n.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _buildAndDrawRoute(int index) async {
    final routeState = context.read<RouteState>();
    if (_userPos == null) {
      routeState.fail('User location not found');
      return;
    }

    final destination = _destinations[index];
    routeState.start();

    try {
      final req = RouteRequest(
        fromLat: _userPos!.latitude,
        fromLng: _userPos!.longitude,
        toLat: destination.poi.latitude,
        toLng: destination.poi.longitude,
        profile: destination.mode,
      );

      final resp = await _routeService.buildRoute(req);
      routeState.setRoute(resp);
      if (destination.poi.id > 0) {
        await _poiService.markVisited(destination.poi.id);
      }

      setState(() {
        destination.distanceM = resp.distanceM;
        destination.durationS = resp.durationS;
        _activeDestination = index;
        _selectedPoi = destination.poi;
      });
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

  Future<void> _toggleFavorite() async {
    if (_selectedPoi == null) return;
    final poi = _selectedPoi!;
    try {
      if (_favoritePoiIds.contains(poi.id)) {
        await _poiService.removeFavorite(poi.id);
        if (!mounted) return;
        setState(() => _favoritePoiIds.remove(poi.id));
      } else {
        await _poiService.addFavorite(poi.id);
        if (!mounted) return;
        setState(() => _favoritePoiIds.add(poi.id));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.favoriteActionFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final poiState = context.watch<PoiState>();
    final routeState = context.watch<RouteState>();
    final isFavorite =
        _selectedPoi != null &&
        _selectedPoi!.id > 0 &&
        _favoritePoiIds.contains(_selectedPoi!.id);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _base.withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.destinations,
                          style: const TextStyle(color: _base, fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showDestinationSheet(),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_destinations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.noDestinations, style: const TextStyle(color: _base)),
                    )
                  else
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = _destinations[i];
                          final active = _activeDestination == i;
                          final eta = d.durationS == null ? '--' : '${(d.durationS! / 60).toStringAsFixed(0)} min';
                          final dist = d.distanceM == null ? '--' : '${(d.distanceM! / 1000).toStringAsFixed(1)} km';
                          return InkWell(
                            onTap: () => _buildAndDrawRoute(i),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFFFFF3D9) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _base.withOpacity(0.18)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.poi.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: _base, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                                        onPressed: () => _showDestinationSheet(editIndex: i),
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                                        onPressed: () {
                                          setState(() {
                                            _destinations.removeAt(i);
                                            if (_activeDestination == i) {
                                              _activeDestination = null;
                                              _polylines = {};
                                            } else if (_activeDestination != null && _activeDestination! > i) {
                                              _activeDestination = _activeDestination! - 1;
                                            }
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${d.mode.toUpperCase()} • $dist • $eta',
                                    style: TextStyle(color: _base.withOpacity(0.7), fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: TextButton(
                                      onPressed: () => _buildAndDrawRoute(i),
                                      child: Text(l10n.directions),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
                  onTap: _onMapTap,
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
                                _selectedPoi == null ? l10n.tapMarkerOrAdd : _selectedPoi!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _base, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: _base,
                              ),
                              onPressed: _selectedPoi == null ? null : () => _showDestinationSheet(),
                              child: Text(l10n.addDestination),
                            ),
                            IconButton(
                              onPressed: _selectedPoi == null || _selectedPoi!.id <= 0 ? null : _toggleFavorite,
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border_outlined,
                                color: isFavorite ? _accent : _base,
                              ),
                            ),
                          ],
                        ),
                        if (routeState.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${routeState.error}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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
