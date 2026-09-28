import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/crop.dart';
import '../../shared/models/farm.dart';
import '../../shared/services/crop_service.dart';
import '../../shared/services/farm_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// Optionally pass a farmId via route arguments to preselect the farm
/// (e.g. when navigating here from Farm Details).
class AddCropScreen extends StatefulWidget {
  final String? preselectedFarmId;
  const AddCropScreen({super.key, this.preselectedFarmId});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedFarmId;
  DateTime? _plantingDate;
  DateTime? _expectedHarvestDate;
  List<Farm> _farms = [];
  bool _loadingFarms = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedFarmId = widget.preselectedFarmId;
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await FarmService.instance.listFarms();
      if (mounted) {
        setState(() {
          _farms = farms;
          _selectedFarmId ??= farms.isNotEmpty ? farms.first.id : null;
          _loadingFarms = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFarms = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isPlantingDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isPlantingDate) {
        _plantingDate = picked;
      } else {
        _expectedHarvestDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _selectedFarmId == null) return;
    setState(() => _saving = true);

    final crop = Crop(
      id: '',
      farmId: _selectedFarmId!,
      name: _nameController.text.trim(),
      plantingDate: _plantingDate,
      expectedHarvestDate: _expectedHarvestDate,
      status: 'planned',
    );

    try {
      await CropService.instance.createCrop(crop);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loadingFarms) {
      return Scaffold(appBar: AppBar(title: Text(t.addCrop)), body: const LoadingView());
    }
    if (_farms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.addCrop)),
        body: EmptyView(message: t.selectFarmFirst, icon: Icons.landscape_outlined),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.addCrop)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedFarmId,
                decoration: InputDecoration(labelText: t.myFarms, border: const OutlineInputBorder()),
                items: _farms
                    .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFarmId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: t.cropName, border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 2) ? t.requiredField : null,
              ),
              const SizedBox(height: 16),
              _DatePickerField(
                label: t.plantingDate,
                value: _formatDate(_plantingDate),
                onTap: () => _pickDate(isPlantingDate: true),
              ),
              const SizedBox(height: 16),
              _DatePickerField(
                label: t.expectedHarvestDate,
                value: _formatDate(_expectedHarvestDate),
                onTap: () => _pickDate(isPlantingDate: false),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: t.save, onPressed: _submit, loading: _saving),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DatePickerField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value.isEmpty ? '—' : value),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}
