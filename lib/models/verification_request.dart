enum VerificationStatus {
  pending,
  approved,
  rejected,
}

VerificationStatus verificationStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'approved':
      return VerificationStatus.approved;
    case 'rejected':
      return VerificationStatus.rejected;
    default:
      return VerificationStatus.pending;
  }
}

class VerificationRequest {
  final String id;
  final String userId;
  final String? propertyId;
  final String documentType;
  final String documentUrl;
  final VerificationStatus status;
  final DateTime createdAt;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    required this.createdAt,
  });

  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    return VerificationRequest(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      propertyId: map['property_id']?.toString(),
      documentType: map['document_type']?.toString() ?? '',
      documentUrl: map['document_url']?.toString() ?? '',
      status: verificationStatusFromString(map['status']?.toString()),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
