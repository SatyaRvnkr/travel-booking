import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'controllers/onboarding_controller.dart';
import 'controllers/onboarding_document_store.dart';
import 'models/document_type.dart';
import 'services/document_upload_service.dart';
import 'utils/upload_flow_logger.dart';
import 'widgets/onboarding_layout.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _profileImage;
  bool _uploaded = false;
  final ImagePicker _picker = ImagePicker();
  final OnboardingController _controller = Get.find();
  final DocumentUploadService _uploadService = Get.find();

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (image == null) return;

    final file = File(image.path);

    UploadFlowLogger.step(1, 'Flutter: user selected profile image');
    UploadFlowLogger.json('Local file path', file.path);

    final result = await _uploadService.uploadDocument(
      file: file,
      kind: DocumentKind.profilePhoto,
      side: DocumentSide.single,
    );

    Get.find<OnboardingDocumentStore>().save(
      DocumentKind.profilePhoto,
      DocumentSide.single,
      result,
    );

    if (!mounted) return;
    setState(() {
      _profileImage = file;
      _uploaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Profile Photo',
      subtitle: 'Take a clear selfie for your driver profile',
      bottomButton: primaryButton(
        label: 'Upload & continue',
        onPressed: _uploaded ? () => _controller.goToAadhar() : null,
      ),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffF3F3F3),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 48, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _pickPhoto,
              child: const Text(
                'Tap to capture photo',
                style: TextStyle(
                  color: Color(0xff1A73E8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
