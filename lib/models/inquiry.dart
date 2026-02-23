/// Represents a single buyer enquiry on a seller's property.
/// Used for both visit requests and (future) expressed interests.
class Inquiry {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final DateTime createdAt;

  const Inquiry({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.createdAt,
  });

  factory Inquiry.fromMap(Map<String, dynamic> m) => Inquiry(
        id: m['id'] as String,
        propertyId: m['property_id'] as String,
        userId: m['user_id'] as String,
        userName: (m['user_name'] as String?)?.trim().isEmpty == true
            ? 'Unknown'
            : (m['user_name'] as String?) ?? 'Unknown',
        userPhone: m['user_phone'] as String? ?? '',
        userEmail: m['user_email'] as String? ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
