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
              Text('Lat: '),
              Text('Lng: '),
              const SizedBox(height: 24),
              if (routeState.loading) const LinearProgressIndicator(),
              if (routeState.error != null)
                Text('Route error: '),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.map,
                      arguments: poi,
                    );
                  },
                  child: const Text('Open on map and build route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
