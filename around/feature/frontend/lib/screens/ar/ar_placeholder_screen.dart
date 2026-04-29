import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/poi.dart';
import '../../services/location_service.dart';
import '../../services/poi_service.dart';
import '../../state/auth_state.dart';

class ArPlaceholderScreen extends StatefulWidget {
  const ArPlaceholderScreen({super.key});

  @override
  State<ArPlaceholderScreen> createState() => _ArPlaceholderScreenState();
}

class _ArPlaceholderScreenState extends State<ArPlaceholderScreen> {
  static const _base = Color(0xFF151E3F);
  static const _accent = Color(0xFFFAA916);

  final _picker = ImagePicker();
  final _location = LocationService();

  XFile? _capturedImage;
  Position? _position;
  List<_ArPoiOverlay> _nearby = [];
  bool _loading = false;

  Future<void> _startArDemo() async {
    if (_loading) return;
    setState(() => _loading = true);

    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    try {
      final pos = await _location.getCurrentPosition();
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1400,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (shot == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRu ? 'Съемка отменена.' : 'Capture canceled.',
            ),
          ),
        );
        return;
      }

      final cfg = context.read<AppConfig>();
      final token = context.read<AuthState>().token;
      final poiService = PoiService(
        ApiClient(cfg.apiBaseUrl, token: token),
        useMock: cfg.useMock,
      );
      final allPoi = await poiService.fetchPoiList();
      final nearest = _nearestPoi(allPoi, pos);

      if (!mounted) return;
      setState(() {
        _capturedImage = shot;
        _position = pos;
        _nearby = nearest;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final message = isRu
          ? 'Не удалось запустить AR-режим: $e'
          : 'Failed to start AR mode: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  List<_ArPoiOverlay> _nearestPoi(List<Poi> allPoi, Position pos) {
    final sorted = [...allPoi]
      ..sort(
        (a, b) => Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          a.latitude,
          a.longitude,
        ).compareTo(
          Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            b.latitude,
            b.longitude,
          ),
        ),
      );

    return sorted.take(3).map((p) {
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        p.latitude,
        p.longitude,
      );
      return _ArPoiOverlay(
        name: p.name,
        distanceM: distance,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final title = isRu ? 'AR-режим' : 'AR Mode';
    final subtitle = isRu
        ? 'Имитация AR с реальным запросом камеры'
        : 'AR simulation with real camera permission';
    final startLabel = isRu ? 'Запустить AR-демо' : 'Start AR demo';
    final retryLabel = isRu ? 'Снять снова' : 'Retake';
    final locationLabel = isRu ? 'Позиция' : 'Position';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _base.withOpacity(0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _base,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(color: _base.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    backgroundColor: const Color(0xFFFFF3D9),
                    side: BorderSide.none,
                    label: Text(
                      isRu ? 'AR demo' : 'AR demo',
                      style: const TextStyle(
                        color: _base,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _startArDemo,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _base,
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(_capturedImage == null ? startLabel : retryLabel),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF3F5FA),
                  child: _capturedImage == null
                      ? Center(
                          child: Text(
                            isRu
                                ? 'Нажмите кнопку выше, чтобы открыть камеру.'
                                : 'Tap the button above to open camera.',
                            style: TextStyle(color: _base.withOpacity(0.7)),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_capturedImage!.path),
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0x66000000), Color(0x22000000)],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _nearby
                                    .map(
                                      (item) => Chip(
                                        backgroundColor: const Color(0xE6FFFFFF),
                                        label: Text(
                                          '${item.name} · ${item.distanceLabel(isRu)}',
                                          style: const TextStyle(
                                            color: _base,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            if (_position != null)
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xE6FFFFFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$locationLabel: ${_position!.latitude.toStringAsFixed(5)}, '
                                    '${_position!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                      color: _base,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArPoiOverlay {
  _ArPoiOverlay({
    required this.name,
    required this.distanceM,
  });

  final String name;
  final double distanceM;

  String distanceLabel(bool isRu) {
    if (distanceM >= 1000) {
      final km = (distanceM / 1000).toStringAsFixed(1);
      return isRu ? '$km км' : '$km km';
    }
    return isRu
        ? '${distanceM.toStringAsFixed(0)} м'
        : '${distanceM.toStringAsFixed(0)} m';
  }
}
