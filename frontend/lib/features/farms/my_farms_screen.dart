import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/farm.dart';
import '../../shared/routes.dart';
import '../../shared/services/farm_service.dart';
import '../../shared/widgets/common_widgets.dart';

class MyFarmsScreen extends StatefulWidget {
  const MyFarmsScreen({super.key});

  @override
  State<MyFarmsScreen> createState() => _MyFarmsScreenState();
}

class _MyFarmsScreenState extends State<MyFarmsScreen> {
  late Future<List<Farm>> _future;

  @override
  void initState() {
    super.initState();
    _future = FarmService.instance.listFarms();
  }

  void _reload() {
    setState(() => _future = FarmService.instance.listFarms());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.myFarms)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).pushNamed(AppRoutes.addEditFarm);
          if (created != null) _reload();
        },
        icon: const Icon(Icons.add),
        label: Text(t.addFarm),
      ),
      body: FutureBuilder<List<Farm>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : t.somethingWentWrong;
            return ErrorView(message: message, onRetry: _reload);
          }
          final farms = snapshot.data ?? [];
          if (farms.isEmpty) {
            return EmptyView(message: t.noFarmsYet, icon: Icons.landscape_outlined);
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: farms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final farm = farms[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.landscape, color: Colors.brown),
                    title: Text(farm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text([farm.district, farm.location].where((s) => s != null && s.isNotEmpty).join(' • ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final changed = await Navigator.of(context)
                          .pushNamed(AppRoutes.farmDetails, arguments: farm.id);
                      if (changed != null) _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
