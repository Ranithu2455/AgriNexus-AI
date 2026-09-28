import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/models/detection_result.dart';
import '../../shared/services/detection_service.dart';
import '../../shared/widgets/common_widgets.dart';

class PestIdentificationScreen extends StatefulWidget {
  const PestIdentificationScreen({super.key});

  @override
  State<PestIdentificationScreen> createState() => _PestIdentificationScreenState();
}

class _PestIdentificationScreenState extends State<PestIdentificationScreen> {
  File? _selectedImage;
  bool _analyzing = false;
  PestResult? _result;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _result = null;
      });
    }
  }

  Future<void> _analyze() async {
    final t = AppLocalizations.of(context)!;
    if (_selectedImage == null) return;
    setState(() => _analyzing = true);
    try {
      final result = await PestService.instance.identify(_selectedImage!);
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.pestIdentification)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : Center(child: Icon(Icons.bug_report_outlined, size: 64, color: Colors.grey.shade400)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(t.captureImage),
                  onPressed: _analyzing ? null : () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t.chooseFromGallery),
                  onPressed: _analyzing ? null : () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _analyzing ? t.analyzing : t.pestIdentification,
            onPressed: _selectedImage == null ? null : _analyze,
            loading: _analyzing,
            icon: Icons.search,
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            if (_result!.isMockResult)
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_result!.predictedPest ?? '-', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  if (_result!.confidence != null)
                    StatusChip(
                      label: '${t.confidence}: ${(_result!.confidence! * 100).toStringAsFixed(0)}%',
                      color: Colors.deepOrange,
                    ),
                ],
              ),
            ),
            if (_result!.symptoms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.symptoms, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _result!.symptoms.map((s) => Text('•  $s')).toList(),
                ),
              ),
            ],
            if (_result!.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.recommendedActions, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _result!.recommendedActions.map((a) => Text('•  $a')).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
