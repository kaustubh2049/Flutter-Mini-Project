import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService._();
  static final instance = ChatService._();

  final _db = Supabase.instance.client;

  // ── Get or create a conversation between buyer & seller for a property ────
  Future<String> getOrCreateConversation({
    required String buyerId,
    required String sellerId,
    required String propertyId,
  }) async {
    // Check if conversation already exists
    final existing = await _db
        .from('conversations')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .eq('property_id', propertyId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create a new conversation
    final result = await _db.from('conversations').insert({
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'property_id': propertyId,
    }).select('id').single();

    return result['id'] as String;
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': message,
    });
  }

  // ── Stream messages in realtime ───────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }
}
