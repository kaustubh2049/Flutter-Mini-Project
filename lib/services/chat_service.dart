import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService._();
  static final instance = ChatService._();

  final SupabaseClient _db = Supabase.instance.client;

  /// Find or create a conversation between buyer and seller for a property
  Future<String> getOrCreateConversation({
    required String buyerId,
    required String sellerId,
    required String propertyId,
  }) async {
    // 1. Check if exists
    final existing = await _db
        .from('conversations')
        .select()
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .eq('property_id', propertyId)
        .maybeSingle();

    if (existing != null) return existing['id'];

    // 2. Create new
    final row = await _db
        .from('conversations')
        .insert({
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'property_id': propertyId,
        })
        .select()
        .single();

    return row['id'];
  }

  /// Send a message in a conversation
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message': message,
    });

    // Update conversation timestamp
    await _db
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()}).eq(
            'id', conversationId);
  }

  /// Stream messages for a specific conversation
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  // ── Fetch all conversations for current user ──────────────────────────────
  Future<List<Map<String, dynamic>>> getConversations() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    // Fetch where user is either buyer or seller, including profile names
    final response = await _db
        .from('conversations')
        .select(
            '*, properties(title, image_urls), buyer:profiles!buyer_id(name), seller:profiles!seller_id(name)')
        .or('buyer_id.eq.$uid,seller_id.eq.$uid')
        .order('created_at', ascending: false);

    return response as List<Map<String, dynamic>>;
  }

  Future<Map<String, dynamic>?> getConversationDetails(
      String conversationId) async {
    final response = await _db
        .from('conversations')
        .select(
            '*, properties(title), buyer:profiles!buyer_id(name), seller:profiles!seller_id(name)')
        .eq('id', conversationId)
        .maybeSingle();
    return response;
  }
}
