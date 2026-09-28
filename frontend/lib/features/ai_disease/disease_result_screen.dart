import 'package:flutter/material.dart';

import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/detection_result.dart';
import '../../shared/widgets/common_widgets.dart';

class DiseaseResultScreen extends StatelessWidget {
  final DiseaseResult result;
  const DiseaseResultScreen({super.key, required this.result});

  Color _confidenceColor(double? confidence) {
    if (confidence == null) return Colors.grey;
    if (confidence >= 0.75) return Colors.red;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.aiPlantDoctor)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (result.isMockResult)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.mockResultNotice, style: TextStyle(color: Colors.amber.shade900))),
                ],
              ),
            ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        result.predictedDisease ?? '-',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (result.confidence != null)
                      StatusChip(
                        label: '${t.confidence}: ${(result.confidence! * 100).toStringAsFixed(0)}%',
                        color: _confidenceColor(result.confidence),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (result.symptoms.isNotEmpty) ...[
            Text(t.symptoms, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.symptoms
                    .map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (result.recommendedActions.isNotEmpty) ...[
            Text(t.recommendedActions, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.recommendedActions
                    .map((a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            result.disclaimer,
            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
