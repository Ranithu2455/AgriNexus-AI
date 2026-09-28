import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/crop.dart';
import '../../shared/models/farm.dart';
import '../../shared/routes.dart';
import '../../shared/services/crop_service.dart';
import '../../shared/services/farm_service.dart';
import '../../shared/widgets/common_widgets.dart';

class FarmDetailsScreen extends StatefulWidget {
  final String farmId;
  const FarmDetailsScreen({super.key, required this.farmId});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  late Future<Farm> _farmFuture;
  late Future<List<Crop>> _cropsFuture;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _farmFuture = FarmService.instance.getFarm(widget.farmId);
    _cropsFuture = CropService.instance.listCrops(farmId: widget.farmId);
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteFarm),
        content: Text(t.confirmDeleteFarm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FarmService.instance.deleteFarm(widget.farmId);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed ? true : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<Farm>(
            future: _farmFuture,
            builder: (context, snapshot) => Text(snapshot.data?.name ?? t.myFarms),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: t.edit,
              onPressed: () async {
                final farm = await _farmFuture;
                if (!mounted) return;
                final updated = await Navigator.of(context)
                    .pushNamed(AppRoutes.addEditFarm, arguments: farm);
                if (updated != null) {
                  _changed = true;
                  setState(_load);
                }
              },
            ),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ),
        body: FutureBuilder<Farm>(
          future: _farmFuture,
          builder: (context, farmSnapshot) {
            if (farmSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (farmSnapshot.hasError || !farmSnapshot.hasData) {
              return ErrorView(message: t.somethingWentWrong, onRetry: () => setState(_load));
            }
            final farm = farmSnapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: t.district, value: farm.district ?? '-'),
                      _InfoRow(label: t.location, value: farm.location ?? '-'),
                      _InfoRow(label: t.farmSize, value: farm.sizeAcres?.toString() ?? '-'),
                      _InfoRow(label: t.soilInfo, value: farm.soilInfo ?? '-'),
                      _InfoRow(label: t.waterAvailability, value: farm.waterAvailability),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.myCrops, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                FutureBuilder<List<Crop>>(
                  future: _cropsFuture,
                  builder: (context, cropSnapshot) {
                    if (cropSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final crops = cropSnapshot.data ?? [];
                    if (crops.isEmpty) {
                      return EmptyView(message: t.noCropsYet, icon: Icons.grass_outlined);
                    }
                    return Column(
                      children: crops
                          .map((crop) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.grass, color: Colors.green),
                                  title: Text(crop.name),
                                  subtitle: Text(crop.status),
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.cropDetails, arguments: crop.id),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(t.addCrop),
                  onPressed: () async {
                    final created = await Navigator.of(context)
                        .pushNamed(AppRoutes.addCrop, arguments: farm.id);
                    if (created != null) setState(_load);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
