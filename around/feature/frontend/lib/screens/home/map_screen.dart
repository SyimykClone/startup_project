import 'package:around/state/auth_state.dart';
import 'dart:async';

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

part 'map_search_bar.dart';
part 'nearby_filters_sheet.dart';
part 'route_info_sheet.dart';
part 'selected_place_card.dart';

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

  final Set<int> _favoritePoiIds = <int>{};
  final List<_DestinationItem> _destinations = [];
  int? _activeDestination;
  int _nextTempPoiId = -1;

  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};
  Timer? _routeAnimationTimer;
  Timer? _routeRefreshTimer;
  bool _routeRefreshInFlight = false;
  LatLng? _lastRouteRefreshPos;
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
      case 'twogis_place':
        return '2GIS';
      default:
        return category;
    }
  }

  String _searchHint() => _isRu ? 'Найти место' : 'Search places';

  String _historyTitle() => _isRu ? 'Недавние маршруты' : 'Recent routes';

  String _emptyHistoryText() =>
      _isRu ? 'История маршрутов пока пустая' : 'No route history yet';

  String _nearbyTitle() => _isRu ? 'Рядом' : 'Nearby';

  String _routeReadyTitle() => _isRu ? 'Маршрут готов' : 'Route ready';

  String _routeDistanceTitle() => _isRu ? 'Расстояние' : 'Distance';

  String _routeTimeTitle() => _isRu ? 'Время' : 'Time';

  String _routeModeTitle() => _isRu ? 'Тип' : 'Mode';

  String _routeCancelText() => _isRu ? 'Отменить' : 'Cancel';

  String _routeFinishText() => _isRu ? 'Завершить' : 'Finish';

  String _routeNearTitle() => _isRu ? 'Вы рядом с местом' : 'You are nearby';

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

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
    }
    return '${meters.toStringAsFixed(0)} ${_isRu ? 'м' : 'm'}';
  }

  String _formatDuration(double seconds) {
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = ((seconds % 3600) / 60).round();
      return _isRu ? '$hours ч $minutes мин' : '${hours}h ${minutes}m';
    }
    return '${(seconds / 60).round()} ${context.l10n.minUnit}';
  }

  String _locationErrorMessage(Object error) {
    if (error is LocationFailure) {
      switch (error.reason) {
        case LocationFailureReason.serviceDisabled:
          return _isRu
              ? 'GPS выключен. Включите геолокацию, чтобы построить маршрут.'
              : 'Location is turned off. Enable it to build a route.';
        case LocationFailureReason.permissionDenied:
          return _isRu
              ? 'Разрешите доступ к геолокации для определения вашей позиции.'
              : 'Allow location access to detect your position.';
        case LocationFailureReason.permissionDeniedForever:
          return _isRu
              ? 'Доступ к геолокации запрещён в настройках приложения.'
              : 'Location access is blocked in app settings.';
        case LocationFailureReason.positionUnavailable:
          return _isRu
              ? 'Позиция пока не определилась. Проверьте GPS и попробуйте ещё раз.'
              : 'Position is not available yet. Check GPS and try again.';
      }
    }
    return context.l10n.userLocationNotFound;
  }

  String _locationActionLabel(Object error) {
    if (error is LocationFailure &&
        error.reason == LocationFailureReason.permissionDeniedForever) {
      return _isRu ? 'Настройки' : 'Settings';
    }
    return _isRu ? 'Включить' : 'Enable';
  }

  Future<void> _openLocationSettingsFor(Object error) async {
    if (error is LocationFailure &&
        error.reason == LocationFailureReason.permissionDeniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    await Geolocator.openLocationSettings();
  }

  void _showLocationProblem(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_locationErrorMessage(error)),
        action: SnackBarAction(
          label: _locationActionLabel(error),
          onPressed: () => _openLocationSettingsFor(error),
        ),
      ),
    );
  }

  String _requestErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (statusCode == 404) {
        return _isRu
            ? 'Сервер ещё не поддерживает этот запрос. Обновите backend-деплой и попробуйте снова.'
            : 'The server does not support this request yet. Update backend deployment and try again.';
      }
      if (statusCode != null) {
        return context.l10n.requestFailed(statusCode);
      }
      if (error.type == DioExceptionType.connectionError) {
        return _isRu
            ? 'Не удалось подключиться к серверу. Проверьте интернет и API URL.'
            : 'Could not connect to the server. Check internet and API URL.';
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return error.toString();
  }

  List<Poi> _filteredPoi(List<Poi> list) {
    final query = _searchQuery.trim().toLowerCase();
    return list.where((poi) {
      final queryOk =
          query.isEmpty ||
          poi.name.toLowerCase().contains(query) ||
          poi.description.toLowerCase().contains(query);
      return queryOk;
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

  void _applyMapFilters() {
    final poi = context.read<PoiState>().poi;
    _drawPoiMarkers([..._filteredPoi(poi), ..._filteredGooglePlaces()]);
  }

  @override
  void dispose() {
    _routeAnimationTimer?.cancel();
    _routeRefreshTimer?.cancel();
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
    } catch (e) {
      _showLocationProblem(e);
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
      } catch (e) {
        _showLocationProblem(e);
      }
    }
    if (_userPos == null) {
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
        SnackBar(content: Text(_requestErrorMessage(e))),
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
        SnackBar(content: Text(_requestErrorMessage(e))),
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

    Poi selectedPoi = fallbackPoi;
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final twoGisCandidates = await _poiService.resolveTapWith2Gis(
        lat: position.latitude,
        lng: position.longitude,
        radiusM: 80,
        locale: locale == 'ru' ? 'ru_RU' : 'en_US',
      );
      selectedPoi = twoGisCandidates.isNotEmpty
          ? twoGisCandidates.first
          : await _poiService.findGooglePlaceNearCoordinates(
                lat: position.latitude,
                lng: position.longitude,
                radiusM: 100,
                language: locale,
              ) ??
              await _poiService.createCustomPoiFromCoordinates(
                lat: position.latitude,
                lng: position.longitude,
                language: locale,
              );
      final placeId = selectedPoi.googlePlaceId;
      if (placeId != null && placeId.isNotEmpty) {
        selectedPoi = await _poiService.fetchGooglePlaceDetails(
          placeId: placeId,
          language: locale,
        );
      }
    } catch (e) {
      try {
        selectedPoi = await _poiService.createCustomPoiFromCoordinates(
          lat: position.latitude,
          lng: position.longitude,
          language: Localizations.localeOf(context).languageCode,
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
    }

    if (!mounted) return;

    final markerPosition = selectedPoi.category == 'google_place' ||
            selectedPoi.category == 'twogis_place'
        ? LatLng(selectedPoi.latitude, selectedPoi.longitude)
        : position;
    final markerIconHue = selectedPoi.category == 'google_place' ||
            selectedPoi.category == 'twogis_place'
        ? BitmapDescriptor.hueRed
        : BitmapDescriptor.hueAzure;
    final refreshedMarkers = _markers.where((m) => m.markerId != tapMarkerId).toSet();
    refreshedMarkers.add(
      Marker(
        markerId: tapMarkerId,
        position: markerPosition,
        infoWindow: InfoWindow(
          title: selectedPoi.name,
          snippet: selectedPoi.address ?? selectedPoi.description,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerIconHue),
      ),
    );

    final existingTempIndex = _destinations.indexWhere((d) => d.poi.id < 0);
    final existingCustomIndex = _destinations.indexWhere((d) => d.poi.category == 'custom');
    final replaceIndex = existingCustomIndex >= 0 ? existingCustomIndex : existingTempIndex;
    final targetIndex = replaceIndex >= 0 ? replaceIndex : _destinations.length;

    setState(() {
      _markers = refreshedMarkers;
      _selectedPoi = selectedPoi;
      if (replaceIndex >= 0) {
        _destinations[replaceIndex] = _DestinationItem(
          poi: selectedPoi,
          mode: _destinations[replaceIndex].mode,
        );
      } else {
        _destinations.add(_DestinationItem(poi: selectedPoi, mode: null));
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

  Future<void> _buildAndDrawRoute(
    int index, {
    bool silent = false,
    bool saveHistory = true,
    bool markVisited = false,
    bool animate = true,
  }) async {
    final routeState = context.read<RouteState>();
    if (_userPos == null) {
      try {
        await _loadUserLocation();
      } catch (e) {
        _showLocationProblem(e);
        routeState.fail(_locationErrorMessage(e));
      }
      if (_userPos == null) {
        if (routeState.error == null) {
          routeState.fail(context.l10n.userLocationNotFound);
        }
        return;
      }
    }

    final destination = _destinations[index];
    if (destination.mode == null) {
      routeState.fail(context.l10n.selectTravelModeFirst);
      return;
    }
    if (!silent) routeState.start();

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
      if (markVisited && destination.poi.id > 0) {
        await _poiService.markVisited(destination.poi.id);
      }

      setState(() {
        destination.distanceM = resp.distanceM;
        destination.durationS = resp.durationS;
        _activeDestination = index;
        _selectedPoi = destination.poi;
      });
      _drawRoute(resp, animate: animate);
      _lastRouteRefreshPos = _userPos;
      _startRouteAutoRefresh();
      if (saveHistory) _loadRouteHistory();
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
      if (!silent) {
        routeState.fail(msg);
      }
    }
  }

  void _drawRoute(RouteResponse resp, {bool animate = true}) {
    _routeAnimationTimer?.cancel();
    final coords = (resp.geometry['coordinates'] as List)
        .map((c) => c as List)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    if (coords.length < 2) {
      setState(() => _polylines = <Polyline>{});
      return;
    }

    if (!animate) {
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
      return;
    }

    var visiblePoints = 1;
    const animationSteps = 28;
    final pointsPerTick =
        (coords.length / animationSteps).ceil().clamp(1, coords.length).toInt();

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: coords.take(visiblePoints).toList(),
          width: 5,
          color: _base,
        ),
      };
    });

    _routeAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 28),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        visiblePoints =
            (visiblePoints + pointsPerTick).clamp(0, coords.length).toInt();
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: coords.take(visiblePoints).toList(),
              width: 5,
              color: _base,
            ),
          };
        });

        if (visiblePoints >= coords.length) {
          timer.cancel();
        }
      },
    );
  }

  double? _distanceToActiveDestination() {
    final activeIndex = _activeDestination;
    final userPos = _userPos;
    if (activeIndex == null ||
        activeIndex >= _destinations.length ||
        userPos == null) {
      return null;
    }
    final poi = _destinations[activeIndex].poi;
    return Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      poi.latitude,
      poi.longitude,
    );
  }

  void _startRouteAutoRefresh() {
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      _refreshActiveRouteFromCurrentPosition();
    });
  }

  Future<void> _refreshActiveRouteFromCurrentPosition() async {
    final activeIndex = _activeDestination;
    if (_routeRefreshInFlight ||
        activeIndex == null ||
        activeIndex >= _destinations.length) {
      return;
    }

    _routeRefreshInFlight = true;
    try {
      final pos = await _location.getCurrentPosition();
      final newPos = LatLng(pos.latitude, pos.longitude);
      final lastPos = _lastRouteRefreshPos;
      if (mounted) setState(() => _userPos = newPos);

      final distanceToTarget = _distanceToActiveDestination();
      if (distanceToTarget != null && distanceToTarget <= 70) {
        return;
      }

      if (lastPos != null) {
        final moved = Geolocator.distanceBetween(
          lastPos.latitude,
          lastPos.longitude,
          newPos.latitude,
          newPos.longitude,
        );
        if (moved < 25) return;
      }

      await _buildAndDrawRoute(
        activeIndex,
        silent: true,
        saveHistory: false,
        markVisited: false,
        animate: false,
      );
    } catch (_) {
    } finally {
      _routeRefreshInFlight = false;
    }
  }

  void _cancelActiveRoute() {
    _routeRefreshTimer?.cancel();
    _routeAnimationTimer?.cancel();
    context.read<RouteState>().clear();
    setState(() {
      _polylines = <Polyline>{};
      _activeDestination = null;
      _lastRouteRefreshPos = null;
    });
  }

  Future<void> _finishActiveRoute() async {
    final activeIndex = _activeDestination;
    if (activeIndex == null || activeIndex >= _destinations.length) return;

    final distanceToTarget = _distanceToActiveDestination();
    if (distanceToTarget == null || distanceToTarget > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRu
                ? 'Завершить маршрут можно рядом с объектом.'
                : 'You can finish the route near the destination.',
          ),
        ),
      );
      return;
    }

    final poi = _destinations[activeIndex].poi;
    if (poi.id > 0) {
      try {
        await _poiService.markVisited(poi.id);
      } catch (_) {
      }
    }
    _cancelActiveRoute();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isRu ? 'Маршрут завершён' : 'Route completed',
        ),
      ),
    );
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
      builder: (context) => _RouteHistorySheet(
        title: _historyTitle(),
        emptyText: _emptyHistoryText(),
        loading: _historyLoading,
        history: _routeHistory,
        modeText: _modeText,
        onSelected: (item) {
          Navigator.pop(context);
          final distance =
              '${(item.distanceM / 1000).toStringAsFixed(1)} ${context.l10n.kmUnit}';
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
      ),
    );
  }

  Future<void> _openNearbyFiltersSheet() async {
    const nearbyTypes = [
      'tourist_attraction',
      'cafe',
      'lodging',
      'museum',
      'park',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _NearbyFiltersSheet(
        title: _nearbyTitle(),
        nearbyTypes: nearbyTypes,
        selectedType: _selectedNearbyType,
        loading: _placesLoading,
        typeText: _nearbyTypeText,
        onSelected: (type) {
          Navigator.pop(context);
          _loadGoogleNearby(type);
        },
      ),
    );
  }

  Future<void> _openRoutesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _RoutesSheet(
        destinations: _destinations,
        modeText: _modeText,
        onAdd: () {
          Navigator.pop(context);
          _showDestinationSheet();
        },
        onEdit: (index) {
          Navigator.pop(context);
          _showDestinationSheet(editIndex: index);
        },
        onBuild: (index) {
          Navigator.pop(context);
          _buildAndDrawRoute(index);
        },
      ),
    );
  }

  Widget _buildRouteSummaryCard() {
    final activeIndex = _activeDestination;
    if (activeIndex == null || activeIndex >= _destinations.length) {
      return const SizedBox.shrink();
    }

    final destination = _destinations[activeIndex];
    final selected = _selectedPoi;
    if (selected == null || selected.id != destination.poi.id) {
      return const SizedBox.shrink();
    }

    final distance = destination.distanceM;
    final duration = destination.durationS;
    final mode = destination.mode;
    if (distance == null || duration == null || mode == null) {
      return const SizedBox.shrink();
    }

    final remaining = _distanceToActiveDestination();
    final isNear = remaining != null && remaining <= 90;

    return _RouteSummaryCard(
      title: isNear ? _routeNearTitle() : _routeReadyTitle(),
      distanceLabel: _routeDistanceTitle(),
      timeLabel: _routeTimeTitle(),
      modeLabel: _routeModeTitle(),
      distance: _formatDistance(distance),
      duration: _formatDuration(duration),
      mode: _modeText(mode),
      finishText: _routeFinishText(),
      cancelText: _routeCancelText(),
      canFinish: isNear,
      onFinish: () {
        _finishActiveRoute();
      },
      onCancel: _cancelActiveRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final poiState = context.watch<PoiState>();
    final routeState = context.watch<RouteState>();
    final filteredPoi = [..._filteredPoi(poiState.poi), ..._filteredGooglePlaces()];
    final filteredCount = filteredPoi.length;
    final isFavorite =
        _selectedPoi != null &&
        _selectedPoi!.id > 0 &&
        _favoritePoiIds.contains(_selectedPoi!.id);
    final showRouteSummaryGap =
        _activeDestination != null &&
        _activeDestination! < _destinations.length &&
        _destinations[_activeDestination!].distanceM != null &&
        _selectedPoi?.id == _destinations[_activeDestination!].poi.id;
    final routeActive = showRouteSummaryGap;

    return SafeArea(
      child: Column(
        children: [
          _MapTopPanel(
            searchCtrl: _searchCtrl,
            searchQuery: _searchQuery,
            filteredPoi: filteredPoi,
            placesLoading: _placesLoading,
            foundLabel: _isRu
                ? 'Найдено мест: $filteredCount'
                : 'Places found: $filteredCount',
            title: _selectedNearbyType == null
                ? (_isRu ? 'Карта и поиск' : 'Map and search')
                : _nearbyTypeText(_selectedNearbyType!),
            searchHint: _searchHint(),
            nearbyTitle: _nearbyTitle(),
            historyTitle: _historyTitle(),
            onOpenNearby: _openNearbyFiltersSheet,
            onOpenRoutes: _openRoutesSheet,
            onOpenHistory: _openHistorySheet,
            onSearch: _searchGooglePlaces,
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
              _applyMapFilters();
            },
            onClearSearch: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
              _applyMapFilters();
            },
            onFocusPoi: _focusPoiOnMap,
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
                _SelectedPoiCard(
                  poiLoading: poiState.loading,
                  routeLoading: routeState.loading,
                  selectedPoi: _selectedPoi,
                  isFavorite: isFavorite,
                  routeActive: routeActive,
                  routeSummary: _buildRouteSummaryCard(),
                  showRouteSummaryGap: showRouteSummaryGap,
                  routeError: routeState.error,
                  distanceLabel: _distanceToSelectedLabel,
                  categoryText: _categoryText,
                  onFocus: _focusPoiOnMap,
                  onDirections: () => _showDestinationSheet(),
                  onToggleFavorite: _toggleFavorite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
