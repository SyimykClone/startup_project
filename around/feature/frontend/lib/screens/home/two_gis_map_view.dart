part of 'map_screen.dart';

class _TwoGisMapView extends StatefulWidget {
  const _TwoGisMapView({
    super.key,
    required this.apiKey,
    required this.initialCenter,
    required this.markers,
    required this.polylines,
    required this.userPosition,
    required this.onMapReady,
    required this.onTap,
    required this.onMarkerTap,
  });

  final String apiKey;
  final LatLng initialCenter;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLng? userPosition;
  final VoidCallback onMapReady;
  final ValueChanged<LatLng> onTap;
  final ValueChanged<String> onMarkerTap;

  @override
  State<_TwoGisMapView> createState() => _TwoGisMapViewState();
}

class _TwoGisMapViewState extends State<_TwoGisMapView> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF4F6FC))
      ..addJavaScriptChannel(
        'MapBridge',
        onMessageReceived: (message) {
          final payload = jsonDecode(message.message) as Map<String, dynamic>;
          final type = payload['type']?.toString();
          if (type == 'ready') {
            _ready = true;
            widget.onMapReady();
            _syncMapData();
          }
          if (type == 'tap') {
            final lat = (payload['lat'] as num).toDouble();
            final lng = (payload['lng'] as num).toDouble();
            widget.onTap(LatLng(lat, lng));
          }
          if (type == 'markerTap') {
            widget.onMarkerTap(payload['id'].toString());
          }
        },
      )
      ..loadHtmlString(
        _html(
          apiKey: widget.apiKey,
          lat: widget.initialCenter.latitude,
          lng: widget.initialCenter.longitude,
        ),
        baseUrl: 'https://mapgl.2gis.com',
      );
  }

  @override
  void didUpdateWidget(covariant _TwoGisMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        (oldWidget.markers != widget.markers ||
            oldWidget.polylines != widget.polylines ||
            oldWidget.userPosition != widget.userPosition)) {
      _syncMapData();
    }
  }

  void moveTo(LatLng position, {double zoom = 15}) {
    if (!_ready) return;
    final js =
        'window.moveTo(${position.longitude}, ${position.latitude}, $zoom);';
    _controller.runJavaScript(js);
  }

  void _syncMapData() {
    if (!_ready) return;
    final data = {
      'markers': widget.markers.map((marker) {
        return {
          'id': marker.markerId.value,
          'lat': marker.position.latitude,
          'lng': marker.position.longitude,
          'title': marker.infoWindow.title ?? '',
        };
      }).toList(),
      'polylines': widget.polylines.map((polyline) {
        return {
          'id': polyline.polylineId.value,
          'points': polyline.points
              .map((point) => [point.longitude, point.latitude])
              .toList(),
          'color':
              '#${polyline.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
          'width': polyline.width,
        };
      }).toList(),
      'user': widget.userPosition == null
          ? null
          : {
              'lat': widget.userPosition!.latitude,
              'lng': widget.userPosition!.longitude,
            },
    };
    _controller.runJavaScript('window.setMapData(${jsonEncode(data)});');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apiKey.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF4F6FC),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: const Text(
          '2GIS API key is missing. Add TWOGIS_API_KEY to assets/.env',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _MapScreenState._base,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return WebViewWidget(controller: _controller);
  }

  String _html({
    required String apiKey,
    required double lat,
    required double lng,
  }) {
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://mapgl.2gis.com/api/js/v1"></script>
  <style>
    html, body, #map { width: 100%; height: 100%; margin: 0; padding: 0; }
    body { background: #f4f6fc; overflow: hidden; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    const map = new mapgl.Map('map', {
      key: '$apiKey',
      center: [$lng, $lat],
      zoom: 12,
    });
    let markers = [];
    let polylines = [];
    let userMarker = null;

    function post(payload) {
      if (window.MapBridge) {
        window.MapBridge.postMessage(JSON.stringify(payload));
      }
    }

    function normalizeCoords(coords) {
      if (!coords) return null;
      if (Array.isArray(coords) && coords.length >= 2) {
        return { lng: Number(coords[0]), lat: Number(coords[1]) };
      }
      const lng = coords.lng ?? coords.lon ?? coords.longitude;
      const lat = coords.lat ?? coords.latitude;
      if (lng === undefined || lat === undefined) return null;
      return { lng: Number(lng), lat: Number(lat) };
    }

    map.on('click', function(event) {
      const coords = normalizeCoords(event.lngLat || event.coordinates);
      if (!coords || Number.isNaN(coords.lng) || Number.isNaN(coords.lat)) return;
      post({ type: 'tap', lng: coords.lng, lat: coords.lat });
    });

    window.moveTo = function(lng, lat, zoom) {
      map.setCenter([lng, lat]);
      if (zoom) map.setZoom(zoom);
    };

    window.setMapData = function(data) {
      markers.forEach(function(marker) { marker.destroy(); });
      polylines.forEach(function(line) { line.destroy(); });
      markers = [];
      polylines = [];

      (data.markers || []).forEach(function(item) {
        const marker = new mapgl.Marker(map, {
          coordinates: [item.lng, item.lat],
        });
        if (marker.on) {
          marker.on('click', function() {
            post({ type: 'markerTap', id: item.id });
          });
        }
        if (marker.getContainer) {
          marker.getContainer().addEventListener('click', function(event) {
            event.stopPropagation();
            post({ type: 'markerTap', id: item.id });
          });
        }
        markers.push(marker);
      });

      (data.polylines || []).forEach(function(item) {
        if (!item.points || item.points.length < 2) return;
        const line = new mapgl.Polyline(map, {
          coordinates: item.points,
          color: item.color || '#151E3F',
          width: item.width || 5,
        });
        polylines.push(line);
      });

      if (data.user) {
        if (userMarker) userMarker.destroy();
        userMarker = new mapgl.Marker(map, {
          coordinates: [data.user.lng, data.user.lat],
          icon: 'https://docs.2gis.com/img/mapgl/marker.svg',
        });
      }
    };

    post({ type: 'ready' });
  </script>
</body>
</html>
''';
  }
}
