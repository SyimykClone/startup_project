import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/poi.dart';
import '../../services/poi_service.dart';
import '../../state/poi_state.dart';

class PoiListScreen extends StatefulWidget {
  const PoiListScreen({super.key});

  @override
  State<PoiListScreen> createState() => _PoiListScreenState();
}

class _PoiListScreenState extends State<PoiListScreen> {
  late PoiService _service;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final cfg = context.read<AppConfig>();
    _service = PoiService(ApiClient(cfg.apiBaseUrl), useMock: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = context.read<PoiState>();
    state.setLoading(true);
    state.setError(null);

    try {
      final list = await _service.fetchPoiList();
      state.setPoi(list);
    } catch (e) {
      state.setError(e.toString());
    } finally {
      state.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<PoiState>();

    return Scaffold(
      appBar: AppBar(title: const Text("POI List")),
      body: st.loading
          ? const Center(child: CircularProgressIndicator())
          : st.error != null
              ? Center(child: Text("Error: ${st.error}"))
              : ListView.builder(
                  itemCount: st.poi.length,
                  itemBuilder: (_, i) {
                    final Poi p = st.poi[i];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text(p.description),

                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
    );
  }
}
