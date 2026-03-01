import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';

class SelectedFile {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final String? extension;
  final String? mimeType;

  const SelectedFile({
    required this.name,
    this.path,
    this.bytes,
    this.extension,
    this.mimeType,
  });
}

class FilePickerScreen extends StatelessWidget {
  final String title;
  final bool allowImages;
  final bool allowPdf;
  final bool allowAny;
  final bool allowCamera;

  const FilePickerScreen({
    Key? key,
    required this.title,
    this.allowImages = true,
    this.allowPdf = true,
    this.allowAny = true,
    this.allowCamera = true,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) {
      return;
    }
    if (images.length == 1) {
      final image = images.first;
      final bytes = await image.readAsBytes();
      final name = image.name.isNotEmpty
          ? image.name
          : image.path.split('/').last;
      Navigator.of(context).pop(
        SelectedFile(
          name: name,
          path: image.path,
          bytes: bytes,
          extension: image.path.split('.').last.toLowerCase(),
          mimeType: image.mimeType,
        ),
      );
      return;
    }

    final selected = await Navigator.of(context).push<_SelectedImage>(
      MaterialPageRoute(
        builder: (_) => _MultiImagePickerScreen(images: images),
      ),
    );
    if (selected == null) {
      return;
    }
    final bytes = await selected.file.readAsBytes();
    final name = selected.file.name.isNotEmpty
        ? selected.file.name
        : selected.file.path.split('/').last;
    Navigator.of(context).pop(
      SelectedFile(
        name: name,
        path: selected.file.path,
        bytes: bytes,
        extension: selected.file.path.split('.').last.toLowerCase(),
        mimeType: selected.file.mimeType,
      ),
    );
  }

  Future<void> _pickPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    Navigator.of(context).pop(
      SelectedFile(
        name: file.name,
        path: file.path,
        bytes: file.bytes,
        extension: file.extension,
      ),
    );
  }

  Future<void> _pickAny(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    Navigator.of(context).pop(
      SelectedFile(
        name: file.name,
        path: file.path,
        bytes: file.bytes,
        extension: file.extension,
      ),
    );
  }

  Future<void> _pickCamera(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    final name = image.name.isNotEmpty
        ? image.name
        : image.path.split('/').last;
    Navigator.of(context).pop(
      SelectedFile(
        name: name,
        path: image.path,
        bytes: bytes,
        extension: image.path.split('.').last.toLowerCase(),
        mimeType: image.mimeType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          if (allowImages)
            _PickerOption(
              icon: Icons.photo_library,
              title: 'Photo',
              subtitle: 'Choose from gallery',
              onTap: () => _pickImage(context),
            ),
          if (allowPdf)
            _PickerOption(
              icon: Icons.picture_as_pdf,
              title: 'PDF',
              subtitle: 'Pick a PDF document',
              onTap: () => _pickPdf(context),
            ),
          if (allowAny)
            _PickerOption(
              icon: Icons.folder_open,
              title: 'All files',
              subtitle: 'Browse files',
              onTap: () => _pickAny(context),
            ),
          if (allowCamera)
            _PickerOption(
              icon: Icons.photo_camera,
              title: 'Camera',
              subtitle: 'Take a photo',
              onTap: () => _pickCamera(context),
            ),
        ],
      ),
    );
  }
}

class _SelectedImage {
  final XFile file;

  const _SelectedImage(this.file);
}

class _MultiImagePickerScreen extends StatelessWidget {
  final List<XFile> images;

  const _MultiImagePickerScreen({required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select a photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(_SelectedImage(image)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _XFileThumbnail(file: image),
            ),
          );
        },
      ),
    );
  }
}

class _XFileThumbnail extends StatelessWidget {
  const _XFileThumbnail({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            color: AppColors.backgroundLight,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textSecondary,
            ),
          );
        }
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.backgroundLight,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
              ),
            );
          },
        );
      },
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'OpenSans',
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}

