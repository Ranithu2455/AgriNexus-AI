import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/farm.dart';
import '../../shared/services/farm_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// Pass an existing [Farm] via route arguments to edit it; pass nothing (or
/// null) to create a new one.
class AddEditFarmScreen extends StatefulWidget {
  final Farm? existingFarm;
  const AddEditFarmScreen({super.key, this.existingFarm});

  @override
  State<AddEditFarmScreen> createState() => _AddEditFarmScreenState();
}

class _AddEditFarmScreenState extends State<AddEditFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _districtController;
  late final TextEditingController _locationController;
  late final TextEditingController _sizeController;
  late final TextEditingController _soilController;
  String _waterAvailability = 'moderate';
  bool _saving = false;

  bool get _isEditing => widget.existingFarm != null;

  @override
  void initState() {
    super.initState();
    final farm = widget.existingFarm;
    _nameController = TextEditingController(text: farm?.name ?? '');
    _districtController = TextEditingController(text: farm?.district ?? '');
    _locationController = TextEditingController(text: farm?.location ?? '');
    _sizeController = TextEditingController(text: farm?.sizeAcres?.toString() ?? '');
    _soilController = TextEditingController(text: farm?.soilInfo ?? '');
    _waterAvailability = farm?.waterAvailability ?? 'moderate';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _locationController.dispose();
    _sizeController.dispose();
    _soilController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final farm = Farm(
      id: widget.existingFarm?.id ?? '',
      name: _nameController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      sizeAcres: double.tryParse(_sizeController.text.trim()),
      soilInfo: _soilController.text.trim().isEmpty ? null : _soilController.text.trim(),
      waterAvailability: _waterAvailability,
    );

    try {
      if (_isEditing) {
        await FarmService.instance.updateFarm(widget.existingFarm!.id, farm);
      } else {
        await FarmService.instance.createFarm(farm);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? t.editFarm : t.addFarm)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: t.farmName, border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 2) ? t.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(labelText: t.district, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: t.location, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sizeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t.farmSize, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soilController,
                maxLines: 2,
                decoration: InputDecoration(labelText: t.soilInfo, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _waterAvailability,
                decoration: InputDecoration(labelText: t.waterAvailability, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'abundant', child: Text(t.waterAvailabilityAbundant)),
                  DropdownMenuItem(value: 'moderate', child: Text(t.waterAvailabilityModerate)),
                  DropdownMenuItem(value: 'limited', child: Text(t.waterAvailabilityLimited)),
                  DropdownMenuItem(value: 'none', child: Text(t.waterAvailabilityNone)),
                ],
                onChanged: (v) => setState(() => _waterAvailability = v ?? 'moderate'),
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
