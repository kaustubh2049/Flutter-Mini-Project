import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService.instance);

final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(chatServiceProvider).getConversations();
});
