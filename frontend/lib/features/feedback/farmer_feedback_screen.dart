import 'package:flutter/material.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/feedback.dart';
import '../../shared/services/feedback_service.dart';
import '../../shared/widgets/common_widgets.dart';

class FarmerFeedbackScreen extends StatefulWidget {
  const FarmerFeedbackScreen({super.key});

  @override
  State<FarmerFeedbackScreen> createState() => _FarmerFeedbackScreenState();
}

class _FarmerFeedbackScreenState extends State<FarmerFeedbackScreen> {
  final _descriptionController = TextEditingController();
  String _selectedType = kFeedbackTypes.first;
  bool _submitting = false;
  late Future<List<FarmerFeedback>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = FeedbackService.instance.listMine();
  }

  String _typeLabel(AppLocalizations t, String type) {
    switch (type) {
      case 'waterlogging':
        return t.feedbackWaterlogging;
      case 'drought':
        return t.feedbackDrought;
      case 'salinity':
        return t.feedbackSalinity;
      case 'pest_outbreak':
        return t.feedbackPestOutbreak;
      case 'disease_outbreak':
        return t.feedbackDiseaseOutbreak;
      case 'unexpected_weather':
        return t.feedbackUnexpectedWeather;
      case 'crop_growth_problem':
        return t.feedbackCropGrowthProblem;
      default:
        return t.feedbackOther;
    }
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    try {
      await FeedbackService.instance.submit(
        feedbackType: _selectedType,
        description: _descriptionController.text.trim(),
      );
      _descriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.feedbackSubmitted)));
        setState(() => _historyFuture = FeedbackService.instance.listMine());
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.farmerFeedback)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(labelText: t.feedbackType, border: const OutlineInputBorder()),
                  items: kFeedbackTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(_typeLabel(t, type))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v ?? kFeedbackTypes.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: t.description, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: t.submitFeedback, onPressed: _submit, loading: _submitting),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(t.myReports, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<FarmerFeedback>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return EmptyView(message: t.noDataYet);
              }
              return Column(
                children: items
                    .map((f) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                            title: Text(_typeLabel(t, f.feedbackType)),
                            subtitle: f.description != null && f.description!.isNotEmpty
                                ? Text(f.description!)
                                : null,
                            trailing: Text(
                              '${f.createdAt.year}-${f.createdAt.month.toString().padLeft(2, '0')}-${f.createdAt.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
