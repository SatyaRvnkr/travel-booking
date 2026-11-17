import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AadhaarProfile {
  final String name;
  final String address;
  final String mobile;
  final String dateOfBirth;

  const AadhaarProfile({
    required this.name,
    required this.address,
    required this.mobile,
    required this.dateOfBirth,
  });
}

class DigilockerFetchResult {
  final AadhaarProfile profile;
  final Map<String, dynamic> issuedFile;

  const DigilockerFetchResult({
    required this.profile,
    required this.issuedFile,
  });
}

class DigilockerService {
  static const String transactionKey = 'digilocker_transaction_id';
  static const String _apiKey = '6sAAbM5xcd1H1AofuGHYKABHB9G5mXsc';
  static const String _eaadhaarUrl =
      'https://api.gridlines.io/digilocker/eaadhaar';
  static const String _issuedFilesUrl =
      'https://api.gridlines.io/digilocker/issued-files';
  static const String _issuedFileUrl =
      'https://api.gridlines.io/digilocker/issued-file';

  static void saveTransactionId(String transactionId) {
    final value = transactionId.trim();
    if (value.isEmpty) return;
    GetStorage().write(transactionKey, value);
  }

  static String? get transactionId {
    final value = GetStorage().read(transactionKey)?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// GET eAadhaar, read the file, GET issued files, POST issued-file.
  Future<DigilockerFetchResult> fetchAfterRedirect() async {
    final transactionId = DigilockerService.transactionId;
    if (transactionId == null) {
      throw Exception(
        'DigiLocker transaction id is missing. Verify Aadhaar again.',
      );
    }

    final eaadhaar = await _get(_eaadhaarUrl, transactionId);
    final eaadhaarData = _dataOf(eaadhaar);
    final link = eaadhaarData['eaadhaar_link']?.toString();
    final xmlProfile = await _profileFromEaadhaarLink(link);

    final issuedFiles = await _get(_issuedFilesUrl, transactionId);
    final filesData = _dataOf(issuedFiles);
    final files = filesData['issued_files'];
    if (files is! List || files.isEmpty) {
      throw Exception('DigiLocker did not return issued files.');
    }

    Map<String, dynamic>? aadhaarFile;
    for (final item in files) {
      if (item is! Map) continue;
      final file = Map<String, dynamic>.from(item);
      final name = file['name']?.toString().toLowerCase() ?? '';
      if (name.contains('aadhaar') || name.contains('aadhar')) {
        aadhaarFile = file;
        break;
      }
    }
    aadhaarFile ??= Map<String, dynamic>.from(files.first as Map);

    final fileUri = aadhaarFile['uri']?.toString() ??
        aadhaarFile['file_uri']?.toString() ??
        aadhaarFile['fileUri']?.toString();
    if (fileUri == null || fileUri.isEmpty) {
      throw Exception('Aadhaar file uri was not returned.');
    }

    final issuedFile = await _post(
      _issuedFileUrl,
      transactionId,
      {'file_uri': fileUri, 'format': 'JSON'},
    );

    debugPrint('DigiLocker issued-file fetched');
    final jsonProfile = _profileFromJson(issuedFile);
    return DigilockerFetchResult(
      profile: _mergeProfiles(xmlProfile, jsonProfile),
      issuedFile: issuedFile,
    );
  }

  Future<AadhaarProfile> _profileFromEaadhaarLink(String? link) async {
    if (link == null || link.isEmpty) {
      return const AadhaarProfile(
        name: '',
        address: '',
        mobile: '',
        dateOfBirth: '',
      );
    }
    try {
      final response = await http
          .get(Uri.parse(link))
          .timeout(const Duration(seconds: 40));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const AadhaarProfile(
          name: '',
          address: '',
          mobile: '',
          dateOfBirth: '',
        );
      }
      final body = response.body.trimLeft();
      if (body.startsWith('{') || body.startsWith('[')) {
        final decoded = jsonDecode(body);
        return _profileFromJson(decoded);
      }
      return _profileFromXml(body);
    } catch (e) {
      debugPrint('eAadhaar file read failed: $e');
      return const AadhaarProfile(
        name: '',
        address: '',
        mobile: '',
        dateOfBirth: '',
      );
    }
  }

  AadhaarProfile _profileFromXml(String xml) {
    final name = _xmlAttr(xml, 'Poi', 'name');
    final dob = _xmlAttr(xml, 'Poi', 'dob');
    final mobile = _xmlAttr(xml, 'Poi', 'phone') ??
        _xmlAttr(xml, 'Poi', 'mobile') ??
        _xmlAttr(xml, 'Poi', 'm');
    final address = [
      _xmlAttr(xml, 'Poa', 'co'),
      _xmlAttr(xml, 'Poa', 'house'),
      _xmlAttr(xml, 'Poa', 'street'),
      _xmlAttr(xml, 'Poa', 'lm'),
      _xmlAttr(xml, 'Poa', 'loc'),
      _xmlAttr(xml, 'Poa', 'vtc'),
      _xmlAttr(xml, 'Poa', 'subdist'),
      _xmlAttr(xml, 'Poa', 'dist'),
      _xmlAttr(xml, 'Poa', 'state'),
      _xmlAttr(xml, 'Poa', 'pc'),
      _xmlAttr(xml, 'Poa', 'po'),
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

    return AadhaarProfile(
      name: name ?? '',
      address: address,
      mobile: mobile ?? '',
      dateOfBirth: dob ?? '',
    );
  }

  String? _xmlAttr(String xml, String tag, String attribute) {
    final match = RegExp(
      '<$tag\\b[^>]*\\b$attribute="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(xml);
    final value = match?.group(1);
    if (value == null || value.trim().isEmpty) return null;
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  AadhaarProfile _profileFromJson(dynamic node) {
    final found = <String, String>{};
    _walkJson(node, found);
    return AadhaarProfile(
      name: found['name'] ?? '',
      address: found['address'] ?? '',
      mobile: found['mobile'] ?? '',
      dateOfBirth: found['dob'] ?? '',
    );
  }

  void _walkJson(dynamic node, Map<String, String> found) {
    if (node is Map) {
      node.forEach((key, value) {
        final name = key.toString().toLowerCase().replaceAll('_', '');
        if (value is String && value.trim().isNotEmpty) {
          final text = value.trim();
          if (text.toLowerCase() == 'aadhaar card') return;
          if (found['name'] == null &&
              (name == 'name' || name == 'fullname' || name == 'residentname')) {
            found['name'] = text;
          } else if (found['dob'] == null &&
              (name == 'dob' || name == 'dateofbirth' || name == 'birthdate')) {
            found['dob'] = text;
          } else if (found['mobile'] == null &&
              (name == 'mobile' ||
                  name == 'mobilenumber' ||
                  name == 'phone' ||
                  name == 'phonenumber')) {
            found['mobile'] = text;
          } else if (found['address'] == null &&
              (name == 'address' || name == 'fulladdress')) {
            found['address'] = text;
          }
        } else {
          _walkJson(value, found);
        }
      });
    } else if (node is List) {
      for (final item in node) {
        _walkJson(item, found);
      }
    }
  }

  AadhaarProfile _mergeProfiles(AadhaarProfile xml, AadhaarProfile json) {
    String pick(String first, String second) =>
        first.trim().isNotEmpty ? first.trim() : second.trim();
    return AadhaarProfile(
      name: pick(xml.name, json.name),
      address: pick(xml.address, json.address),
      mobile: pick(xml.mobile, json.mobile),
      dateOfBirth: pick(xml.dateOfBirth, json.dateOfBirth),
    );
  }

  Future<Map<String, dynamic>> _get(String url, String transactionId) async {
    debugPrint('GET $url');
    final response = await http
        .get(Uri.parse(url), headers: _headers(transactionId))
        .timeout(const Duration(seconds: 40));
    return _parse(response);
  }

  Future<Map<String, dynamic>> _post(
    String url,
    String transactionId,
    Map<String, dynamic> body,
  ) async {
    debugPrint('POST $url');
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers(transactionId),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 40));
    return _parse(response);
  }

  Map<String, String> _headers(String transactionId) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Auth-Type': 'API-Key',
      'X-Transaction-ID': transactionId,
      'X-API-Key': _apiKey,
      'json': 'true',
    };
  }

  Map<String, dynamic> _parse(http.Response response) {
    debugPrint('DigiLocker status: ${response.statusCode}');
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('DigiLocker returned an invalid response.');
    }
    final root = Map<String, dynamic>.from(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = root['data'];
      final message = (data is Map ? data['message'] : null)?.toString() ??
          root['message']?.toString() ??
          'DigiLocker request failed.';
      throw Exception(message);
    }
    return root;
  }

  Map<String, dynamic> _dataOf(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return root;
  }
}
