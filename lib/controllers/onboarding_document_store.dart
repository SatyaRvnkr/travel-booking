import 'package:get/get.dart';

import '../models/document_type.dart';
import '../models/uploaded_document.dart';

class OnboardingDocumentStore extends GetxService {
  final Map<String, UploadedDocument> _documents = {};

  void save(DocumentKind kind, DocumentSide side, UploadedDocument doc) {
    _documents[documentSideKey(kind, side)] = doc;
  }

  UploadedDocument? get(DocumentKind kind, DocumentSide side) {
    return _documents[documentSideKey(kind, side)];
  }

  List<Map<String, String>> toSubmitPayload() {
    return _documents.entries
        .map(
          (e) => {
            'key': e.key,
            'objectKey': e.value.objectKey,
            'fileUrl': e.value.fileUrl,
          },
        )
        .toList();
  }
}
