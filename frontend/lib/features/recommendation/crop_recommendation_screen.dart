import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/recommendation.dart';
import '../../shared/services/recommendation_service.dart';
import '../../shared/widgets/common_widgets.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phController = TextEditingController(text: '6.0');
  final _nController = TextEditingController(text: '30');
  final _pController = TextEditingController(text: '20');
  final _kController = TextEditingController(text: '20');
  final _tempController = TextEditingController(text: '28');
  final _humidityController = TextEditingController(text: '70');
  final _rainfallController = TextEditingController(text: '150');
  final _locationController = TextEditingController();
  String? _season;
  String _waterAvailability = 'moderate';
  bool _loading = false;
  CropRecommendationResult? _result;

  @override
  void dispose() {
    _phController.dispose();
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _rainfallController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await RecommendationService.instance.getRecommendations(
        soilPh: double.parse(_phController.text),
        nitrogen: double.parse(_nController.text),
        phosphorus: double.parse(_pController.text),
        potassium: double.parse(_kController.text),
        temperatureC: double.parse(_tempController.text),
        humidityPct: double.parse(_humidityController.text),
        rainfallMm: double.parse(_rainfallController.text),
        location: _locationController.text.trim(),
        season: _season,
        waterAvailability: _waterAvailability,
      );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'high':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _numberField(String label, TextEditingController controller) {
    final t = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => (v == null || double.tryParse(v) == null) ? t.requiredField : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.cropRecommendation)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _numberField(t.soilPh, _phController)),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(t.temperature, _tempController)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _numberField(t.nitrogen, _nController)),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(t.phosphorus, _pController)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _numberField(t.potassium, _kController)),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(t.humidity, _humidityController)),
                ]),
                const SizedBox(height: 12),
                _numberField(t.rainfall, _rainfallController),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: t.location, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _season,
                      decoration: InputDecoration(labelText: t.season, border: const OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('—')),
                        DropdownMenuItem(value: 'Yala', child: Text('Yala')),
                        DropdownMenuItem(value: 'Maha', child: Text('Maha')),
                      ],
                      onChanged: (v) => setState(() => _season = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _waterAvailability,
                      decoration:
                          InputDecoration(labelText: t.waterAvailability, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'abundant', child: Text(t.waterAvailabilityAbundant)),
                        DropdownMenuItem(value: 'moderate', child: Text(t.waterAvailabilityModerate)),
                        DropdownMenuItem(value: 'limited', child: Text(t.waterAvailabilityLimited)),
                        DropdownMenuItem(value: 'none', child: Text(t.waterAvailabilityNone)),
                      ],
                      onChanged: (v) => setState(() => _waterAvailability = v ?? 'moderate'),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                PrimaryButton(label: t.getRecommendations, onPressed: _submit, loading: _loading),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            ..._result!.recommendations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(r.cropName, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            StatusChip(
                              label: '${t.suitability}: ${r.suitabilityScore.toStringAsFixed(0)} — ${r.suitabilityLevel}',
                              color: _levelColor(r.suitabilityLevel),
                            ),
                          ],
                        ),
                        if (r.reasons.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(t.reasons, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ...r.reasons.map((x) => Text('•  $x', style: const TextStyle(fontSize: 13))),
                        ],
                        if (r.warnings.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(t.warnings,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.orange.shade800)),
                          ...r.warnings.map((x) => Text('•  $x',
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade800))),
                        ],
                      ],
                    ),
                  ),
                )),
            Text(
              _result!.disclaimer,
              style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
