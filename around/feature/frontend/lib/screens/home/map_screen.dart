import 'package:around/state/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  const MapScreen({super.key, this.initialPoi});

  final Poi? initialPoi;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _DestinationItem {
  _DestinationItem({required this.poi, required this.mode});

  final Poi poi;
  String? mode;
  double? distanceM;
  double? durationS;
}

class _MapScreenState extends State<MapScreen> {
  static const _accent = Color(0xFFFAA916);
  static const _base = Color(0xFF151E3F);
  static const _modes = ['walking', 'driving'];

  GoogleMapController? _map;

  late PoiService _poiService;
  late RouteService _routeService;
  final _location = LocationService();
  final _searchCtrl = TextEditingController();

  LatLng? _userPos;
  Poi? _selectedPoi;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final Set<int> _favoritePoiIds = <int>{};
  final List<_DestinationItem> _destinations = [];
  int? _activeDestination;
  int _nextTempPoiId = -1;

  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};
  List<RouteHistoryItem> _routeHistory = [];
  bool _historyLoading = false;
  List<Poi> _googlePlaces = [];
  bool _placesLoading = false;
  String? _selectedNearbyType;

  bool _servicesInitialized = false;
  bool _initialPoiHandled = false;

  String _modeText(String mode) {
    switch (mode) {
      case 'walking':
        return context.l10n.modeWalking;
      case 'driving':
        return context.l10n.modeDriving;
      default:
        return mode;
    }
  }

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

  String _categoryText(String category) {
    switch (category) {
      case 'all':
        return _isRu ? 'Все' : 'All';
      case 'monument':
        return _isRu ? 'Памятники' : 'Monuments';
      case 'memorial':
        return _isRu ? 'Мемориалы' : 'Memorials';
      case 'custom':
        return _isRu ? 'Мои точки' : 'My points';
      case 'google_place':
        return _isRu ? 'Google Places' : 'Google Places';
      default:
        return category;
    }
  }

  String _searchHint() => _isRu ? 'Найти место' : 'Search places';

  String _historyTitle() => _isRu ? 'Недавние маршруты' : 'Recent routes';

  String _emptyHistoryText() =>
      _isRu ? 'История маршрутов пока пустая' : 'No route history yet';

  String _nearbyTitle() => _isRu ? 'Рядом' : 'Nearby';

  String _nearbyTypeText(String type) {
    switch (type) {
      case 'tourist_attraction':
        return _isRu ? 'Достопримечательности' : 'Sights';
      case 'cafe':
        return _isRu ? 'Кафе' : 'Cafe';
      case 'lodging':
        return _isRu ? 'Отели' : 'Hotels';
      case 'museum':
        return _isRu ? 'Музеи' : 'Museums';
      case 'park':
        return _isRu ? 'Парки' : 'Parks';
      default:
        return type;
    }
  }

  String _distanceToSelectedLabel(Poi poi) {
    final userPos = _userPos;
    if (userPos == null) return '';
    final meters = Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      poi.latitude,
      poi.longitude,
    );
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
    }
    return '${meters.toStringAsFixed(0)} ${_isRu ? 'м' : 'm'}';
  }

  List<Poi> _filteredPoi(List<Poi> list) {
    final query = _searchQuery.trim().toLowerCase();
    return list.where((poi) {
      final categoryOk =
          _selectedCategory == 'all' || poi.category == _selectedCategory;
      final queryOk =
          query.isEmpty ||
          poi.name.toLowerCase().contains(query) ||
          poi.description.toLowerCase().contains(query);
      return categoryOk && queryOk;
    }).toList();
  }

  List<Poi> _filteredGooglePlaces() {
    final query = _searchQuery.trim().toLowerCase();
    return _googlePlaces.where((poi) {
      return query.isEmpty ||
          poi.name.toLowerCase().contains(query) ||
          poi.description.toLowerCase().contains(query) ||
          (poi.address ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<String> _availableCategories(List<Poi> list) {
    final categories = list
        .map((p) => p.category)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...categories];
  }

  void _applyMapFilters() {
    final poi = context.read<PoiState>().poi;
    _drawPoiMarkers([..._filteredPoi(poi), ..._filteredGooglePlaces()]);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    try {
      await _loadUserLocation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.userLocationNotFound)),
        );
      }
    }
    await _loadPoiAndDrawMarkers();
    await _loadFavorites();
    await _loadRouteHistory();
    await _openInitialPoiIfNeeded();
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
      _applyMapFilters();
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
    }
  }

  Future<void> _loadRouteHistory() async {
    if (_historyLoading) return;
    setState(() => _historyLoading = true);
    try {
      final history = await _routeService.fetchHistory(limit: 8);
      if (!mounted) return;
      setState(() => _routeHistory = history);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _loadGoogleNearby(String placeType) async {
    if (_placesLoading) return;
    if (_userPos == null) {
      try {
        await _loadUserLocation();
      } catch (_) {}
    }
    if (_userPos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.userLocationNotFound)),
      );
      return;
    }

    setState(() {
      _placesLoading = true;
      _selectedNearbyType = placeType;
      _searchQuery = '';
    });
    _searchCtrl.clear();
    try {
      final places = await _poiService.fetchGoogleNearbyPlaces(
        lat: _userPos!.latitude,
        lng: _userPos!.longitude,
        placeType: placeType,
        radiusM: 2500,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() => _googlePlaces = places);
      _applyMapFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _placesLoading = false);
    }
  }

  Future<void> _searchGooglePlaces() async {
    final query = _searchQuery.trim();
    if (query.isEmpty || _placesLoading) return;
    if (_userPos == null) {
      try {
        await _loadUserLocation();
      } catch (_) {}
    }

    setState(() {
      _placesLoading = true;
      _selectedNearbyType = null;
    });
    try {
      final places = await _poiService.searchGooglePlaces(
        query: query,
        lat: _userPos?.latitude,
        lng: _userPos?.longitude,
        radiusM: 5000,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() => _googlePlaces = places);
      _applyMapFilters();
      if (places.isNotEmpty) {
        _focusPoiOnMap(places.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _placesLoading = false);
    }
  }

  Future<void> _selectPoi(Poi poi) async {
    setState(() => _selectedPoi = poi);
    final placeId = poi.googlePlaceId;
    if (placeId == null || placeId.isEmpty) return;

    try {
      final detailed = await _poiService.fetchGooglePlaceDetails(
        placeId: placeId,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() => _selectedPoi = detailed);
    } catch (_) {}
  }

  void _drawPoiMarkers(List<Poi> list) {
    final markers = <Marker>{};

    for (final p in list) {
      final markerId = MarkerId('poi_${p.id}');
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: p.rating == null ? null : '★ ${p.rating}',
          ),
          onTap: () => _selectPoi(p),
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

    final tapMarkerId = const MarkerId('tap_point');
    final nonTapMarkers = _markers
        .where((m) => m.markerId != tapMarkerId)
        .toSet();
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
          SnackBar(
            content: Text(l10n.couldNotResolveAddress),
          ),
        );
      }
    }

    if (!mounted) return;

    final refreshedMarkers = _markers.where((m) => m.markerId != tapMarkerId).toSet();
    refreshedMarkers.add(
      Marker(
        markerId: tapMarkerId,
        position: position,
        infoWindow: InfoWindow(title: customPoi.name, snippet: customPoi.description),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    final existingTempIndex = _destinations.indexWhere((d) => d.poi.id < 0);
    final existingCustomIndex = _destinations.indexWhere((d) => d.poi.category == 'custom');
    final replaceIndex = existingCustomIndex >= 0 ? existingCustomIndex : existingTempIndex;
    final targetIndex = replaceIndex >= 0 ? replaceIndex : _destinations.length;

    setState(() {
      _markers = refreshedMarkers;
      _selectedPoi = customPoi;
      if (replaceIndex >= 0) {
        _destinations[replaceIndex] = _DestinationItem(
          poi: customPoi,
          mode: _destinations[replaceIndex].mode,
        );
      } else {
        _destinations.add(_DestinationItem(poi: customPoi, mode: null));
      }
      _activeDestination = targetIndex;
    });

    await _showDestinationSheet(editIndex: targetIndex);
  }

  Future<void> _showDestinationSheet({int? editIndex}) async {
    final poiState = context.read<PoiState>();
    if (poiState.poi.isEmpty) {
      await _loadPoiAndDrawMarkers();
    }
    if (!mounted || poiState.poi.isEmpty) return;

    Poi selectedPoi;
    String? selectedMode;

    if (editIndex != null) {
      final d = _destinations[editIndex];
      selectedPoi = d.poi;
      selectedMode = d.mode;
    } else {
      selectedPoi = _selectedPoi ?? poiState.poi.first;
      selectedMode = null;
    }

    final options = _buildDestinationOptions(poiState.poi, selectedPoi);

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
              child: SingleChildScrollView(
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
                    style: TextStyle(fontWeight: FontWeight.w700, color: _base),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _modes.map((mode) {
                      final selected = selectedMode == mode;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(_modeText(mode)),
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
                            if (selectedMode == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.selectTravelModeFirst),
                                ),
                              );
                              return;
                            }
                            if (editIndex == null) {
                              setState(() {
                                _destinations.add(
                                  _DestinationItem(
                                    poi: selectedPoi,
                                    mode: selectedMode!,
                                  ),
                                );
                                _activeDestination = _destinations.length - 1;
                                _selectedPoi = selectedPoi;
                              });
                            } else {
                              setState(() {
                                _destinations[editIndex] = _DestinationItem(
                                  poi: selectedPoi,
                                  mode: selectedMode!,
                                );
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
      try {
        await _loadUserLocation();
      } catch (_) {}
      if (_userPos == null) {
        routeState.fail(context.l10n.userLocationNotFound);
        return;
      }
    }

    final destination = _destinations[index];
    if (destination.mode == null) {
      routeState.fail(context.l10n.selectTravelModeFirst);
      return;
    }
    routeState.start();

    try {
      final req = RouteRequest(
        fromLat: _userPos!.latitude,
        fromLng: _userPos!.longitude,
        toLat: destination.poi.latitude,
        toLng: destination.poi.longitude,
        profile: destination.mode!,
        destinationName: destination.poi.name,
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
      _loadRouteHistory();
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
          msg = context.l10n.requestFailed(e.response!.statusCode!);
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

  List<Poi> _buildDestinationOptions(List<Poi> allPoi, Poi selectedPoi) {
    if (selectedPoi.category != 'custom') {
      final options = <Poi>[...allPoi];
      final hasSelected = options.any((p) => p.id == selectedPoi.id);
      if (!hasSelected) {
        options.insert(0, selectedPoi);
      }
      return options;
    }

    final nearest = [...allPoi]
      ..sort(
        (a, b) => Geolocator.distanceBetween(
          selectedPoi.latitude,
          selectedPoi.longitude,
          a.latitude,
          a.longitude,
        ).compareTo(
          Geolocator.distanceBetween(
            selectedPoi.latitude,
            selectedPoi.longitude,
            b.latitude,
            b.longitude,
          ),
        ),
      );

    return [
      selectedPoi,
      ...nearest.where((p) => p.id != selectedPoi.id).take(5),
    ];
  }

  Future<void> _openInitialPoiIfNeeded() async {
    final initialPoi = widget.initialPoi;
    if (_initialPoiHandled || initialPoi == null) return;
    _initialPoiHandled = true;

    final markerId = MarkerId('poi_${initialPoi.id}');
    if (!_markers.any((m) => m.markerId == markerId)) {
      final refreshed = {..._markers};
      refreshed.add(
        Marker(
          markerId: markerId,
          position: LatLng(initialPoi.latitude, initialPoi.longitude),
          infoWindow: InfoWindow(title: initialPoi.name),
          onTap: () => setState(() => _selectedPoi = initialPoi),
        ),
      );
      setState(() => _markers = refreshed);
    }

    setState(() => _selectedPoi = initialPoi);
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(initialPoi.latitude, initialPoi.longitude),
        15,
      ),
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.favoriteActionFailed(e.toString()))),
      );
    }
  }

  void _focusPoiOnMap(Poi poi) {
    final markerId = MarkerId('poi_${poi.id}');
    final refreshed = _markers.where((m) => m.markerId != markerId).toSet();
    refreshed.add(
      Marker(
        markerId: markerId,
        position: LatLng(poi.latitude, poi.longitude),
        infoWindow: InfoWindow(title: poi.name),
        onTap: () => _selectPoi(poi),
      ),
    );
    setState(() {
      _selectedPoi = poi;
      _markers = refreshed;
    });
    _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(poi.latitude, poi.longitude), 15),
    );
  }

  Future<void> _openHistorySheet() async {
    await _loadRouteHistory();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _historyTitle(),
                  style: const TextStyle(
                    color: _base,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_historyLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_routeHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: Text(_emptyHistoryText())),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _routeHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final item = _routeHistory[index];
                        final distance =
                            '${(item.distanceM / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
                        final minutes =
                            '${(item.durationS / 60).toStringAsFixed(0)} ${context.l10n.minUnit}';
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _base.withOpacity(0.12)),
                          ),
                          leading: const Icon(Icons.history, color: _base),
                          title: Text(
                            item.destinationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_modeText(item.profile)} · $distance · $minutes',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            final poi = Poi(
                              id: -item.id,
                              name: item.destinationName,
                              description: distance,
                              latitude: item.toLat,
                              longitude: item.toLng,
                              category: 'custom',
                            );
                            _focusPoiOnMap(poi);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final poiState = context.watch<PoiState>();
    final routeState = context.watch<RouteState>();
    final categories = _availableCategories(poiState.poi);
    final filteredPoi = [..._filteredPoi(poiState.poi), ..._filteredGooglePlaces()];
    final filteredCount = filteredPoi.length;
    const nearbyTypes = [
      'tourist_attraction',
      'cafe',
      'lodging',
      'museum',
      'park',
    ];
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
                          context.l10n.destinations,
                          style: TextStyle(
                            color: _base,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showDestinationSheet(),
                        icon: const Icon(Icons.add),
                        label: Text(context.l10n.add),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: _historyTitle(),
                        onPressed: _openHistorySheet,
                        icon: const Icon(Icons.history, color: _base),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: _searchHint(),
                      prefixIcon: IconButton(
                        onPressed: _searchGooglePlaces,
                        icon: const Icon(Icons.search),
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                                _applyMapFilters();
                              },
                              icon: const Icon(Icons.close),
                            ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyMapFilters();
                    },
                    onSubmitted: (_) => _searchGooglePlaces(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final category = categories[index];
                        return ChoiceChip(
                          selected: _selectedCategory == category,
                          label: Text(_categoryText(category)),
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                            _applyMapFilters();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _nearbyTitle(),
                        style: TextStyle(
                          color: _base.withOpacity(0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_placesLoading) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearbyTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final type = nearbyTypes[index];
                        return ActionChip(
                          avatar: Icon(
                            _selectedNearbyType == type
                                ? Icons.check
                                : Icons.travel_explore,
                            size: 18,
                          ),
                          label: Text(_nearbyTypeText(type)),
                          onPressed: _placesLoading
                              ? null
                              : () => _loadGoogleNearby(type),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isRu
                          ? 'Найдено мест: $filteredCount'
                          : 'Places found: $filteredCount',
                      style: TextStyle(
                        color: _base.withOpacity(0.64),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_searchQuery.trim().isNotEmpty && filteredPoi.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredPoi.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final poi = filteredPoi[index];
                          return ActionChip(
                            avatar: const Icon(Icons.place_outlined, size: 18),
                            label: Text(
                              poi.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _focusPoiOnMap(poi),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_destinations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.noDestinations,
                        style: TextStyle(color: _base),
                      ),
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = _destinations[i];
                          final active = _activeDestination == i;
                          final modeLabel = d.mode == null
                              ? context.l10n.selectMode
                              : d.mode!.toUpperCase();
                          final eta = d.durationS == null
                              ? '--'
                              : '${(d.durationS! / 60).toStringAsFixed(0)} ${context.l10n.minUnit}';
                          final dist = d.distanceM == null
                              ? '--'
                              : '${(d.distanceM! / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
                          return InkWell(
                            onTap: d.mode == null
                                ? () => _showDestinationSheet(editIndex: i)
                                : () => _buildAndDrawRoute(i),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFFFF3D9)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _base.withOpacity(0.18),
                                ),
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
                                          style: const TextStyle(
                                            color: _base,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 26,
                                              height: 26,
                                            ),
                                        onPressed: () =>
                                            _showDestinationSheet(editIndex: i),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 26,
                                              height: 26,
                                            ),
                                        onPressed: () {
                                          setState(() {
                                            _destinations.removeAt(i);
                                            if (_activeDestination == i) {
                                              _activeDestination = null;
                                              _polylines = {};
                                            } else if (_activeDestination !=
                                                    null &&
                                                _activeDestination! > i) {
                                              _activeDestination =
                                                  _activeDestination! - 1;
                                            }
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$modeLabel · $dist · $eta',
                                    style: TextStyle(
                                      color: _base.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: TextButton(
                                      onPressed: d.mode == null
                                          ? () => _showDestinationSheet(editIndex: i)
                                          : () => _buildAndDrawRoute(i),
                                      child: Text(context.l10n.directions),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPoi == null
                                        ? context.l10n.tapMarkerOrAdd
                                        : _selectedPoi!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _base,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (_selectedPoi != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      _selectedPoi!.address ??
                                          _selectedPoi!.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _base.withOpacity(0.68),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          _distanceToSelectedLabel(_selectedPoi!),
                                          style: TextStyle(
                                            color: _base.withOpacity(0.78),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (_selectedPoi!.rating != null)
                                          Text(
                                            '★ ${_selectedPoi!.rating!.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              color: _accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (_selectedPoi!.category != null)
                                      Text(
                                        _categoryText(_selectedPoi!.category!),
                                        style: TextStyle(
                                          color: _base.withOpacity(0.58),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_selectedPoi != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _focusPoiOnMap(_selectedPoi!),
                                  icon: const Icon(
                                    Icons.my_location_outlined,
                                    size: 18,
                                  ),
                                  label: Text(context.l10n.openOnMap),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _showDestinationSheet(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: _base,
                                  ),
                                  icon: const Icon(Icons.route, size: 18),
                                  label: Text(context.l10n.directions),
                                ),
                              ),
                              IconButton(
                                onPressed: _selectedPoi!.id <= 0
                                    ? null
                                    : _toggleFavorite,
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border_outlined,
                                  color: isFavorite ? _accent : _base,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (routeState.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${context.l10n.errorLabel}: ${routeState.error}',
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
