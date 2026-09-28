import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../shared/api/api_config.dart';
import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/state/auth_provider.dart';
import '../../shared/widgets/common_widgets.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _fullNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _locationController = TextEditingController();
  final _infoController = TextEditingController();
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().currentUser?.farmerProfile;
    _fullNameController.text = profile?.fullName ?? '';
    _districtController.text = profile?.district ?? '';
    _locationController.text = profile?.location ?? '';
    _infoController.text = profile?.farmerInfo ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _districtController.dispose();
    _locationController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(
        fullName: _fullNameController.text.trim(),
        district: _districtController.text.trim(),
        location: _locationController.text.trim(),
        farmerInfo: _infoController.text.trim(),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().refreshCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saveChanges)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      await AuthService.instance.uploadProfileImage(File(picked.path));
      if (!mounted) return;
      await context.read<AuthProvider>().refreshCurrentUser();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.changePhoto)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final profile = context.watch<AuthProvider>().currentUser?.farmerProfile;
    final imageUrl = profile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(title: Text(t.myProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: imageUrl != null
                      ? NetworkImage('${ApiConfig.baseUrl}$imageUrl')
                      : null,
                  child: imageUrl == null
                      ? const Icon(Icons.person, size: 48, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _uploadingImage ? null : _changePhoto,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: _uploadingImage
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(labelText: t.fullName, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _districtController,
                    decoration: InputDecoration(labelText: t.district, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(labelText: t.location, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _infoController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: t.farmerInfo, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: t.saveChanges, onPressed: _save, loading: _saving),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
