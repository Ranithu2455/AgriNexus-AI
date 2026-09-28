import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/routes.dart';
import '../../shared/services/detection_service.dart';
import '../../shared/widgets/common_widgets.dart';

class AiPlantDoctorScreen extends StatefulWidget {
  const AiPlantDoctorScreen({super.key});

  @override
  State<AiPlantDoctorScreen> createState() => _AiPlantDoctorScreenState();
}

class _AiPlantDoctorScreenState extends State<AiPlantDoctorScreen> {
  File? _selectedImage;
  bool _analyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _analyze() async {
    final t = AppLocalizations.of(context)!;
    if (_selectedImage == null) return;
    setState(() => _analyzing = true);
    try {
      final result = await DiseaseService.instance.detect(_selectedImage!);
      if (mounted) {
        Navigator.of(context).pushNamed(AppRoutes.diseaseResult, arguments: result);
      }
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
      appBar: AppBar(title: Text(t.aiPlantDoctor)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(Icons.local_florist_outlined, size: 64, color: Colors.grey.shade400),
                      ),
              ),
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
              label: _analyzing ? t.analyzing : t.aiPlantDoctor,
              onPressed: _selectedImage == null ? null : _analyze,
              loading: _analyzing,
              icon: Icons.search,
            ),
          ],
        ),
      ),
    );
  }
}
