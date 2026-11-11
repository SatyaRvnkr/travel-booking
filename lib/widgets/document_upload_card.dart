import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../config/presigned_upload_config.dart';
import '../controllers/onboarding_document_store.dart';
import '../models/document_type.dart';
import '../services/document_upload_service.dart';
import '../utils/upload_flow_logger.dart';

class DocumentUploadCard extends StatefulWidget {
  final DocumentKind documentKind;
  final String frontLabel;
  final String backLabel;
  final bool showBackSide;
  final ValueChanged<bool>? onUploadStatusChanged;

  const DocumentUploadCard({
    super.key,
    required this.documentKind,
    this.frontLabel = 'Upload front side',
    this.backLabel = 'Upload back side',
    this.showBackSide = true,
    this.onUploadStatusChanged,
  });

  @override
  State<DocumentUploadCard> createState() => DocumentUploadCardState();
}

class DocumentUploadCardState extends State<DocumentUploadCard> {
  File? _frontImage;
  File? _backImage;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _frontLoading = false;
  bool _backLoading = false;
  final ImagePicker _picker = ImagePicker();

  bool get isComplete =>
      _frontUploaded && (!widget.showBackSide || _backUploaded);

  DocumentUploadService get _uploadService => Get.find<DocumentUploadService>();

  Future<void> _pickAndUpload(bool isFront) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final file = File(image.path);
    final side = widget.showBackSide
        ? (isFront ? DocumentSide.front : DocumentSide.back)
        : DocumentSide.single;

    UploadFlowLogger.step(1, 'User selected image');
    UploadFlowLogger.json('Local file path', file.path);
    UploadFlowLogger.json('Document', '${widget.documentKind.apiValue} / ${side.apiValue}');

    setState(() {
      if (isFront) {
        _frontLoading = true;
      } else {
        _backLoading = true;
      }
    });

    try {
      // 1) POST /upload-url  2) PUT S3  3) POST /document
      final result = await _uploadService.uploadDocument(
        file: file,
        kind: widget.documentKind,
        side: side,
      );

      Get.find<OnboardingDocumentStore>().save(
        widget.documentKind,
        side,
        result,
      );

      if (!mounted) return;

      setState(() {
        if (isFront) {
          _frontImage = file;
          _frontUploaded = true;
          _frontLoading = false;
        } else {
          _backImage = file;
          _backUploaded = true;
          _backLoading = false;
        }
      });

      Get.snackbar(
        'Uploaded to S3',
        result.fileUrl,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      widget.onUploadStatusChanged?.call(isComplete);
    } on PresignedUrlNotConfiguredException catch (e) {
      if (!mounted) return;
      setState(() {
        if (isFront) {
          _frontLoading = false;
        } else {
          _backLoading = false;
        }
      });
      Get.snackbar('Config', e.message, snackPosition: SnackPosition.BOTTOM);
    } on DocumentUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        if (isFront) {
          _frontLoading = false;
        } else {
          _backLoading = false;
        }
      });
      Get.snackbar('Upload', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isFront) {
          _frontLoading = false;
        } else {
          _backLoading = false;
        }
      });
      Get.snackbar('Upload failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _uploadTile(
          label: widget.frontLabel,
          image: _frontImage,
          uploaded: _frontUploaded,
          loading: _frontLoading,
          onTap: _frontLoading ? null : () => _pickAndUpload(true),
        ),
        if (widget.showBackSide) ...[
          const SizedBox(height: 12),
          _uploadTile(
            label: widget.backLabel,
            image: _backImage,
            uploaded: _backUploaded,
            loading: _backLoading,
            onTap: _backLoading ? null : () => _pickAndUpload(false),
          ),
        ],
      ],
    );
  }

  Widget _uploadTile({
    required String label,
    required File? image,
    required bool uploaded,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xffEAF2FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffB8D4FF)),
        ),
        child: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                uploaded ? Icons.check_circle : Icons.upload_file,
                color: uploaded ? Colors.green : const Color(0xff1A73E8),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loading
                    ? 'Uploading to S3...'
                    : uploaded
                        ? 'Uploaded to S3'
                        : label,
                style: TextStyle(
                  color: uploaded ? Colors.green.shade700 : const Color(0xff1A73E8),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(image, width: 40, height: 40, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }
}
