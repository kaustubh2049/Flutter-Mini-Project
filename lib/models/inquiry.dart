enum InquiryType { visit, interest }

/// Represents a single buyer enquiry on a seller's property.
/// Used for both visit requests and expressed interests.
class Inquiry {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final DateTime createdAt;
  final DateTime? appointmentAt;
  final InquiryType type;

  const Inquiry({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.createdAt,
    this.appointmentAt,
    required this.type,
  });

  factory Inquiry.fromMap(Map<String, dynamic> m, InquiryType type) => Inquiry(
        id: m['id'] as String,
        propertyId: m['property_id'] as String,
        userId: m['user_id'] as String,
        userName: (m['user_name'] as String?)?.trim().isEmpty == true
            ? 'Unknown'
            : (m['user_name'] as String?) ?? 'Unknown',
        userPhone: m['user_phone'] as String? ?? '',
        userEmail: m['user_email'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
        appointmentAt: m['appointment_at'] != null
            ? DateTime.parse(m['appointment_at'] as String)
            : null,
        type: type,
      );

}

