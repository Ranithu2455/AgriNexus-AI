import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing.dart';
import '../providers/listing_provider.dart';

/// Lets a seller pick a photo from camera/gallery and upload it to a
/// listing that already exists (images attach to a listing_id, so this is
/// used after the listing itself has been created).
class ListingImageManager extends StatefulWidget {
  final Listing listing;
  final ListingProvider provider;

  const ListingImageManager({super.key, required this.listing, required this.provider});

  @override
  State<ListingImageManager> createState() => _ListingImageManagerState();
}

class _ListingImageManagerState extends State<ListingImageManager> {
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      await widget.provider.uploadImage(
        widget.listing.id,
        picked.path,
        setPrimary: widget.listing.images.isEmpty,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.listing.images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...images.map((img) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(img.imageUrl, width: 96, height: 96, fit: BoxFit.cover),
                    ),
                  )),
              _uploading
                  ? const SizedBox(width: 96, height: 96, child: Center(child: CircularProgressIndicator()))
                  : InkWell(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Wrap(children: [
                            ListTile(
                              leading: const Icon(Icons.photo_camera_outlined),
                              title: const Text('Take photo'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickAndUpload(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library_outlined),
                              title: const Text('Choose from gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickAndUpload(ImageSource.gallery);
                              },
                            ),
                          ]),
                        ),
                      ),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
