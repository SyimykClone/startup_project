import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/poi.dart';
import '../../services/location_service.dart';
import '../../services/poi_service.dart';
import '../../state/auth_state.dart';

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  static const _base = Color(0xFF151E3F);
  static const _accent = Color(0xFFFAA916);

  final _picker = ImagePicker();
  final _location = LocationService();

  XFile? _capturedImage;
  Position? _position;
  _ArScanTarget? _target;
  bool _loading = false;
  bool _modelAvailable = false;
  bool _tooFar = false;

  Future<void> _startArScan() async {
    if (_loading) return;
    setState(() => _loading = true);

    final isRu = _isRu;

    try {
      final pos = await _location.getCurrentPosition();
      final target = await _findNearestArTarget(pos);
      final modelAvailable = target == null
          ? false
          : await _hasModelAsset(target.modelAsset);

      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 88,
      );

      if (!mounted) return;
      if (shot == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRu ? 'Сканирование отменено.' : 'Scan canceled.'),
          ),
        );
        return;
      }

      setState(() {
        _capturedImage = shot;
        _position = pos;
        _target = target;
        _modelAvailable = modelAvailable;
        _tooFar = target != null && target.distanceM > target.radiusM;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final message = isRu
          ? 'Не удалось запустить AR-сканирование: $e'
          : 'Failed to start AR scan: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool get _isRu => Localizations.localeOf(context).languageCode == 'ru';

  Future<_ArScanTarget?> _findNearestArTarget(Position pos) async {
    final cfg = context.read<AppConfig>();
    final token = context.read<AuthState>().token;
    final poiService = PoiService(
      ApiClient(cfg.apiBaseUrl, token: token),
      useMock: cfg.useMock,
    );

    final arPoi = (await poiService.fetchPoiList())
        .where((poi) => poi.arEnabled && poi.arModelAsset != null)
        .toList();
    if (arPoi.isEmpty) return null;

    arPoi.sort((a, b) {
      final aDistance = _distanceTo(pos, a);
      final bDistance = _distanceTo(pos, b);
      return aDistance.compareTo(bDistance);
    });

    final nearest = arPoi.first;
    return _ArScanTarget.fromPoi(
      poi: nearest,
      distanceM: _distanceTo(pos, nearest),
    );
  }

  double _distanceTo(Position pos, Poi poi) {
    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      poi.latitude,
      poi.longitude,
    );
  }

  Future<bool> _hasModelAsset(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRu = _isRu;
    final title = isRu ? 'AR-сканирование' : 'AR Scan';
    final subtitle = isRu
        ? 'Подойдите к достопримечательности, наведите камеру и получите 3D-модель с описанием.'
        : 'Approach a landmark, scan it with camera, and view a 3D model.';
    final startLabel = _capturedImage == null
        ? (isRu ? 'Сканировать объект' : 'Scan object')
        : (isRu ? 'Сканировать снова' : 'Scan again');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _IntroCard(
              title: title,
              subtitle: subtitle,
              loading: _loading,
              buttonLabel: startLabel,
              onScan: _startArScan,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF3F5FA),
                  child: _capturedImage == null
                      ? _EmptyScanState(isRu: isRu)
                      : _ArScanResult(
                          imagePath: _capturedImage!.path,
                          target: _target,
                          modelAvailable: _modelAvailable,
                          tooFar: _tooFar,
                          position: _position,
                          isRu: isRu,
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

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.buttonLabel,
    required this.onScan,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final String buttonLabel;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ArScreenState._base.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar, color: _ArScreenState._base),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ArScreenState._base,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: _ArScreenState._base.withOpacity(0.72)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onScan,
              style: FilledButton.styleFrom(
                backgroundColor: _ArScreenState._accent,
                foregroundColor: _ArScreenState._base,
              ),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScanState extends StatelessWidget {
  const _EmptyScanState({required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_outlined,
              color: _ArScreenState._base,
              size: 46,
            ),
            const SizedBox(height: 10),
            Text(
              isRu
                  ? 'Нажмите кнопку выше, чтобы открыть камеру и начать сканирование.'
                  : 'Tap the button above to open camera and start scanning.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ArScreenState._base.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArScanResult extends StatelessWidget {
  const _ArScanResult({
    required this.imagePath,
    required this.target,
    required this.modelAvailable,
    required this.tooFar,
    required this.position,
    required this.isRu,
  });

  final String imagePath;
  final _ArScanTarget? target;
  final bool modelAvailable;
  final bool tooFar;
  final Position? position;
  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final target = this.target;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(imagePath), fit: BoxFit.cover),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x77000000), Color(0x11000000), Color(0x99000000)],
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: _ScanStatusCard(target: target, tooFar: tooFar, isRu: isRu),
        ),
        Center(
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _ArScreenState._accent, width: 1.4),
            ),
            clipBehavior: Clip.antiAlias,
            child: target == null
                ? _NoArObjectHint(isRu: isRu)
                : tooFar
                    ? _TooFarHint(target: target, isRu: isRu)
                    : modelAvailable
                        ? ModelViewer(
                            src: target.modelAsset,
                            alt: target.title,
                            autoRotate: true,
                            cameraControls: true,
                            disableZoom: true,
                            backgroundColor: Colors.transparent,
                          )
                        : _MissingModelHint(
                            modelPath: target.modelAsset,
                            isRu: isRu,
                          ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: _BottomInfo(target: target, position: position, isRu: isRu),
        ),
      ],
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({
    required this.target,
    required this.tooFar,
    required this.isRu,
  });

  final _ArScanTarget? target;
  final bool tooFar;
  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final title = target?.title ?? (isRu ? 'AR-объект не найден' : 'No AR object found');
    final subtitle = target == null
        ? (isRu
            ? 'Рядом нет достопримечательности с AR-моделью.'
            : 'There is no nearby landmark with an AR model.')
        : tooFar
            ? target.tooFarLabel(isRu)
            : target.distanceLabel(isRu);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              target == null ? Icons.search_off : Icons.place,
              color: _ArScreenState._base,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ArScreenState._base,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ArScreenState._base.withOpacity(0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Chip(
            backgroundColor: Color(0xFFFFF3D9),
            side: BorderSide.none,
            label: Text(
              'AR',
              style: TextStyle(
                color: _ArScreenState._base,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  const _BottomInfo({
    required this.target,
    required this.position,
    required this.isRu,
  });

  final _ArScanTarget? target;
  final Position? position;
  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final title = isRu ? 'Краткое описание' : 'Short description';
    final description = target?.description ??
        (isRu
            ? 'AR-данные для ближайшего объекта не найдены. Добавьте AR-поля в Supabase для нужной достопримечательности.'
            : 'AR data for the nearest object was not found. Add AR fields in Supabase for the target landmark.');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ArScreenState._base,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _ArScreenState._base.withOpacity(0.78)),
          ),
          if (position != null) ...[
            const SizedBox(height: 8),
            Text(
              'GPS: ${position!.latitude.toStringAsFixed(5)}, '
              '${position!.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                color: _ArScreenState._base.withOpacity(0.58),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoArObjectHint extends StatelessWidget {
  const _NoArObjectHint({required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context) {
    return _CenteredHint(
      icon: Icons.search_off,
      title: isRu ? 'AR-объект не найден' : 'No AR object',
      subtitle: isRu
          ? 'В Supabase пока нет ближайшего POI с включенным AR.'
          : 'There is no nearby POI with AR enabled in Supabase.',
    );
  }
}

class _TooFarHint extends StatelessWidget {
  const _TooFarHint({required this.target, required this.isRu});

  final _ArScanTarget target;
  final bool isRu;

  @override
  Widget build(BuildContext context) {
    return _CenteredHint(
      icon: Icons.social_distance,
      title: isRu ? 'Подойдите ближе' : 'Move closer',
      subtitle: target.tooFarLabel(isRu),
    );
  }
}

class _MissingModelHint extends StatelessWidget {
  const _MissingModelHint({required this.modelPath, required this.isRu});

  final String modelPath;
  final bool isRu;

  @override
  Widget build(BuildContext context) {
    return _CenteredHint(
      icon: Icons.view_in_ar_outlined,
      title: isRu ? '3D-модель не найдена' : '3D model not found',
      subtitle: modelPath,
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _ArScreenState._base, size: 42),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ArScreenState._base,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ArScreenState._base.withOpacity(0.65),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArScanTarget {
  const _ArScanTarget({
    required this.title,
    required this.description,
    required this.modelAsset,
    required this.distanceM,
    required this.radiusM,
  });

  final String title;
  final String description;
  final String modelAsset;
  final double distanceM;
  final int radiusM;

  factory _ArScanTarget.fromPoi({
    required Poi poi,
    required double distanceM,
  }) {
    return _ArScanTarget(
      title: poi.arTitle?.trim().isNotEmpty == true ? poi.arTitle! : poi.name,
      description: poi.arDescription?.trim().isNotEmpty == true
          ? poi.arDescription!
          : poi.description,
      modelAsset: poi.arModelAsset!,
      distanceM: distanceM,
      radiusM: poi.arRadiusM,
    );
  }

  String distanceLabel(bool isRu) {
    if (distanceM >= 1000) {
      final km = (distanceM / 1000).toStringAsFixed(1);
      return isRu ? 'Расстояние: $km км' : 'Distance: $km km';
    }
    return isRu
        ? 'Расстояние: ${distanceM.toStringAsFixed(0)} м'
        : 'Distance: ${distanceM.toStringAsFixed(0)} m';
  }

  String tooFarLabel(bool isRu) {
    return isRu
        ? 'До объекта ${distanceM.toStringAsFixed(0)} м. Нужно подойти ближе ${radiusM} м.'
        : 'Object is ${distanceM.toStringAsFixed(0)} m away. Move within $radiusM m.';
  }
}
