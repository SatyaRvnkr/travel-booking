
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

  DocumentUploadService get _uploadService =>
      Get.find<DocumentUploadService>();

  Future<void> _pickAndUpload(bool isFront) async {
    if (isFront ? _frontLoading : _backLoading) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null || !mounted) return;

    final file = File(image.path);

    final side = widget.showBackSide
        ? (isFront ? DocumentSide.front : DocumentSide.back)
        : DocumentSide.single;

    // Show selected image immediately.
    setState(() {
      if (isFront) {
        _frontImage = file;
        _frontUploaded = false;
        _frontLoading = true;
      } else {
        _backImage = file;
        _backUploaded = false;
        _backLoading = true;
      }
    });

    // Disable Continue until the replacement is uploaded.
    widget.onUploadStatusChanged?.call(false);

    UploadFlowLogger.step(1, 'User selected image');
    UploadFlowLogger.json('Local file path', file.path);
    UploadFlowLogger.json(
      'Document',
      '${widget.documentKind.apiValue} / ${side.apiValue}',
    );

    try {
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
          _frontUploaded = true;
          _frontLoading = false;
        } else {
          _backUploaded = true;
          _backLoading = false;
        }
      });

      Get.snackbar(
        'Upload successful',
        '${isFront ? 'Front' : 'Back'} image uploaded successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      widget.onUploadStatusChanged?.call(isComplete);
    } on PresignedUrlNotConfiguredException catch (e) {
      _handleUploadError(isFront, e.message);
    } on DocumentUploadException catch (e) {
      _handleUploadError(isFront, e.message);
    } catch (e) {
      _handleUploadError(isFront, e.toString());
    }
  }

  void _handleUploadError(bool isFront, String message) {
    if (!mounted) return;

    setState(() {
      if (isFront) {
        _frontLoading = false;
        _frontUploaded = false;
      } else {
        _backLoading = false;
        _backUploaded = false;
      }
    });

    widget.onUploadStatusChanged?.call(isComplete);

    Get.snackbar(
      'Upload failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _removeImage(bool isFront) {
    if (isFront ? _frontLoading : _backLoading) return;

    setState(() {
      if (isFront) {
        _frontImage = null;
        _frontUploaded = false;
      } else {
        _backImage = null;
        _backUploaded = false;
      }
    });

    widget.onUploadStatusChanged?.call(isComplete);
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
          onTap: () => _pickAndUpload(true),
          onRemove: () => _removeImage(true),
        ),
        if (widget.showBackSide) ...[
          const SizedBox(height: 12),
          _uploadTile(
            label: widget.backLabel,
            image: _backImage,
            uploaded: _backUploaded,
            loading: _backLoading,
            onTap: () => _pickAndUpload(false),
            onRemove: () => _removeImage(false),
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
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: uploaded
              ? Colors.green.shade300
              : const Color(0xffB8D4FF),
        ),
      ),
      child: Row(
        children: [
          // Small image preview
          GestureDetector(
            onTap: image != null
                ? () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.file(image),
                  ),
                ),
              );
            }
                : onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 68,
                height: 68,
                color: Colors.white,
                child: image != null
                    ? Image.file(
                  image,
                  fit: BoxFit.cover,
                )
                    : const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 30,
                  color: Color(0xff1A73E8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xff033564),
                  ),
                ),
                const SizedBox(height: 5),
                if (loading)
                  const Row(
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Uploading...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                else if (uploaded)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Uploaded successfully',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    image != null
                        ? 'Upload failed. Tap to retry.'
                        : 'Tap to select image',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // Replace / Remove
          if (!loading && image != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'replace') {
                  onTap();
                } else if (value == 'remove') {
                  onRemove();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'replace',
                  child: Text('Replace image'),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove image'),
                ),
              ],
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xff033564),
              ),
            )
          else if (!loading)
            IconButton(
              onPressed: onTap,
              icon: const Icon(
                Icons.upload,
                color: Color(0xff1A73E8),
              ),
            ),
        ],
      ),
    );
  }
}
