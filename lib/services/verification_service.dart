import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wallet_service.dart';
import 'monetization_service.dart';

import '../models/verification_request.dart';

class VerificationService {
  VerificationService._();
  static final instance = VerificationService._();

  final SupabaseClient _db = Supabase.instance.client;
  final String _bucket = 'verification-docs';

  static const List<String> documentTypes = [
    'Aadhar Card',
    'PAN Card',
    'Property Tax Receipt',
    'Utility Bill',
    'Sale Deed',
  ];

  Future<List<VerificationRequest>> getMyVerificationRequests() async {
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

  // Alias for backward compatibility
  Future<List<VerificationRequest>> fetchMyRequests() => getMyVerificationRequests();

  Future<VerificationRequest> submitVerificationRequest({
    required String documentType,
    required PlatformFile file,
    String? propertyId,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Please log in first.');

    // 1. Deduct from wallet
    await WalletService.instance.deductMoney(
      MonetizationService.VERIFICATION_PRICE,
      'verification',
    );

    // 2. Upload document
    final documentUrl = await _uploadDocument(userId: uid, file: file);

    // 3. Create request
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
    if (file.path != null) return await File(file.path!).readAsBytes();
    throw Exception('File bytes are unavailable.');
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

  bool _isMissingTableError(PostgrestException error, String tableName) {
    final details =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();
    return details.contains('relation') &&
        details.contains(tableName.toLowerCase()) &&
        details.contains('does not exist');
  }

  // Admin Methods
  Future<List<VerificationRequest>> getAllVerificationRequests() async {
    final response = await _db
        .from('verification_requests')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => VerificationRequest.fromMap(row))
        .toList();
  }

  // Alias for backward compatibility
  Future<List<VerificationRequest>> fetchAllRequests() => getAllVerificationRequests();

  Future<void> updateRequestStatus({
    required String requestId,
    required dynamic status, // Handles both String and VerificationStatus enum
    String? propertyId,
    String? userId,
  }) async {
    final statusStr = status is String ? status : status.toString().split('.').last;

    if (statusStr == 'approved') {
      await approveRequest(requestId);
    } else {
      await _db
          .from('verification_requests')
          .update({'status': statusStr}).eq('id', requestId);
    }
  }

  Future<void> approveRequest(String requestId) async {
    final request = await _db
        .from('verification_requests')
        .select()
        .eq('id', requestId)
        .single();

    final propertyId = request['property_id'];
    final userId = request['user_id'];

    // 1. Update request status
    await _db
        .from('verification_requests')
        .update({'status': 'approved'}).eq('id', requestId);

    // 2. Mark property as verified if linked
    if (propertyId != null) {
      await _db
          .from('properties')
          .update({'is_verified': true}).eq('id', propertyId);
    }

    // 3. Mark user profile as verified
    await _db
        .from('profiles')
        .update({'is_verified': true}).eq('id', userId);
  }

  Future<void> rejectRequest(String requestId) async {
    await _db
        .from('verification_requests')
        .update({'status': 'rejected'}).eq('id', requestId);
  }
}
