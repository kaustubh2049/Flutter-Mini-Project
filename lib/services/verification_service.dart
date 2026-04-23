import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/verification_request.dart';

class VerificationService {
  VerificationService._();
  static final instance = VerificationService._();

  final SupabaseClient _db = Supabase.instance.client;
  static const String _bucket = 'verification-docs';

  static const List<String> documentTypes = [
    'Aadhaar',
    'PAN',
    'Property tax document',
    'Sale deed',
    'Electricity bill',
  ];

  Future<List<VerificationRequest>> fetchMyRequests() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final rows = await _db
          .from('verification_requests')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => VerificationRequest.fromMap(row))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingTableError(e, 'verification_requests')) {
        return [];
      }
      rethrow;
    }
  }

  Future<VerificationRequest> submitVerificationRequest({
    required String documentType,
    required PlatformFile file,
    String? propertyId,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Please log in first.');

    final documentUrl = await _uploadDocument(userId: uid, file: file);

    try {
      final row = await _db
          .from('verification_requests')
          .insert({
            'user_id': uid,
            'property_id': propertyId,
            'document_type': documentType,
            'document_url': documentUrl,
            'status': 'pending',
          })
          .select()
          .single();

      return VerificationRequest.fromMap(row);
    } on PostgrestException catch (e) {
      if (_isMissingTableError(e, 'verification_requests')) {
        throw Exception(
          'verification_requests table is missing. Please run the migration SQL first.',
        );
      }
      rethrow;
    }
  }

  Future<String> _uploadDocument({
    required String userId,
    required PlatformFile file,
  }) async {
    final nameParts = file.name.split('.');
    final ext =
        (file.extension ?? (nameParts.length > 1 ? nameParts.last : 'pdf'))
            .toLowerCase();

    final sanitizedName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    try {
      final rawBytes = await _fileBytes(file);
      final bytes = Uint8List.fromList(rawBytes);

      await _db.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentTypeForExtension(ext),
            ),
          );
    } on StorageException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('bucket') && lower.contains('not found')) {
        throw Exception(
          'Storage bucket verification-docs not found. Please create it in Supabase Storage.',
        );
      }
      rethrow;
    }

    return _db.storage.from(_bucket).getPublicUrl(path);
  }

  Future<List<int>> _fileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return File(path).readAsBytes();
    }
    throw Exception('Could not read selected file. Please pick again.');
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<VerificationRequest>> fetchAllRequests() async {
    try {
      final rows = await _db
          .from('verification_requests')
          .select()
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => VerificationRequest.fromMap(row))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingTableError(e, 'verification_requests')) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required VerificationStatus status,
    String? propertyId,
    required String userId,
  }) async {
    final statusString = status.name; // 'pending', 'approved', 'rejected'

    await _db
        .from('verification_requests')
        .update({'status': statusString}).eq('id', requestId);

    if (status == VerificationStatus.approved) {
      if (propertyId != null && propertyId.isNotEmpty) {
        // Verify property
        await _db
            .from('properties')
            .update({'is_verified': true}).eq('id', propertyId);
      } else {
        // Verify user profile
        await _db
            .from('profiles')
            .update({'is_verified': true}).eq('id', userId);
      }
    } else if (status == VerificationStatus.rejected) {
      if (propertyId != null && propertyId.isNotEmpty) {
        await _db
            .from('properties')
            .update({'is_verified': false}).eq('id', propertyId);
      } else {
        await _db
            .from('profiles')
            .update({'is_verified': false}).eq('id', userId);
      }
    }
  }

  bool _isMissingTableError(PostgrestException error, String tableName) {
    final details =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();
    return details.contains('relation') &&
        details.contains(tableName.toLowerCase());
  }
}
