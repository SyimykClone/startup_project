import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/poi.dart';
import '../../state/route_state.dart';
import '../../core/router/app_router.dart';

class PoiDetailScreen extends StatelessWidget {
  final Poi poi;
  const PoiDetailScreen({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    final routeState = context.watch<RouteState>();
    final locale = Localizations.localeOf(context).languageCode;
    final coordinatesLabel = locale == 'ru' ? 'Координаты' : 'Coordinates';
    final routeErrorLabel = locale == 'ru' ? 'Ошибка маршрута' : 'Route error';
    final openMapLabel = locale == 'ru' ? 'Открыть на карте' : 'Open on map';

    return Scaffold(
      appBar: AppBar(title: Text(poi.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poi.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Text(
                '$coordinatesLabel: '
                '${poi.latitude.toStringAsFixed(5)}, '
                '${poi.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 24),
              if (routeState.loading) const LinearProgressIndicator(),
              if (routeState.error != null)
                Text('$routeErrorLabel: ${routeState.error}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.map,
                      arguments: AppShellArgs(initialIndex: 2, initialPoi: poi),
                    );
                  },
                  child: Text(openMapLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
