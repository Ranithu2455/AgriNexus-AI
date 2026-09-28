import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/crop.dart';
import '../../shared/models/farm.dart';
import '../../shared/routes.dart';
import '../../shared/services/crop_service.dart';
import '../../shared/services/farm_service.dart';
import '../../shared/widgets/common_widgets.dart';

class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  late Future<List<Crop>> _cropsFuture;
  List<Farm> _farms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _cropsFuture = CropService.instance.listCrops();
    FarmService.instance.listFarms().then((farms) {
      if (mounted) setState(() => _farms = farms);
    });
  }

  Future<void> _goToAddCrop() async {
    final t = AppLocalizations.of(context)!;
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.selectFarmFirst)));
      return;
    }
    final created = await Navigator.of(context).pushNamed(AppRoutes.addCrop);
    if (created != null) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.myCrops)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddCrop,
        icon: const Icon(Icons.add),
        label: Text(t.addCrop),
      ),
      body: FutureBuilder<List<Crop>>(
        future: _cropsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : t.somethingWentWrong;
            return ErrorView(message: message, onRetry: () => setState(_load));
          }
          final crops = snapshot.data ?? [];
          if (crops.isEmpty) {
            return EmptyView(message: t.noCropsYet, icon: Icons.grass_outlined);
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: crops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final crop = crops[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.grass, color: Colors.green),
                    title: Text(crop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(crop.status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final changed = await Navigator.of(context)
                          .pushNamed(AppRoutes.cropDetails, arguments: crop.id);
                      if (changed != null) setState(_load);
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
