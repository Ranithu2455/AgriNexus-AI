import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/crop.dart';
import '../../shared/services/crop_service.dart';
import '../../shared/widgets/common_widgets.dart';

class CropDetailsScreen extends StatefulWidget {
  final String cropId;
  const CropDetailsScreen({super.key, required this.cropId});

  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  late Future<Crop> _future;
  bool _changed = false;

  static const _statuses = [
    'planned',
    'planted',
    'growing',
    'ready_for_harvest',
    'harvested',
    'failed',
  ];

  @override
  void initState() {
    super.initState();
    _future = CropService.instance.getCrop(widget.cropId);
  }

  String _statusLabel(AppLocalizations t, String status) {
    switch (status) {
      case 'planned':
        return t.cropStatusPlanned;
      case 'planted':
        return t.cropStatusPlanted;
      case 'growing':
        return t.cropStatusGrowing;
      case 'ready_for_harvest':
        return t.cropStatusReadyForHarvest;
      case 'harvested':
        return t.cropStatusHarvested;
      case 'failed':
        return t.cropStatusFailed;
      default:
        return status;
    }
  }

  Future<void> _updateStatus(Crop crop, String newStatus) async {
    try {
      final updated = Crop(
        id: crop.id,
        farmId: crop.farmId,
        name: crop.name,
        plantingDate: crop.plantingDate,
        expectedHarvestDate: crop.expectedHarvestDate,
        status: newStatus,
      );
      await CropService.instance.updateCrop(crop.id, updated);
      _changed = true;
      setState(() => _future = CropService.instance.getCrop(widget.cropId));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Crop crop) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await CropService.instance.deleteCrop(crop.id);
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
          title: FutureBuilder<Crop>(
            future: _future,
            builder: (context, snapshot) => Text(snapshot.data?.name ?? t.myCrops),
          ),
          actions: [
            FutureBuilder<Crop>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(snapshot.data!),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<Crop>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return ErrorView(message: t.somethingWentWrong);
            }
            final crop = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.cropStatus, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: crop.status,
                        isExpanded: true,
                        items: _statuses
                            .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(t, s))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null && v != crop.status) _updateStatus(crop, v);
                        },
                      ),
                      const Divider(height: 24),
                      _InfoRow(label: t.plantingDate, value: crop.plantingDate?.toString().split(' ').first ?? '-'),
                      _InfoRow(
                        label: t.expectedHarvestDate,
                        value: crop.expectedHarvestDate?.toString().split(' ').first ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.cropHistory, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (crop.historyEntries.isEmpty)
                  EmptyView(message: t.noDataYet)
                else
                  ...crop.historyEntries.reversed.map(
                    (h) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(h.event),
                        subtitle: Text(h.details ?? ''),
                        trailing: Text(
                          '${h.recordedAt.year}-${h.recordedAt.month.toString().padLeft(2, '0')}-${h.recordedAt.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
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
