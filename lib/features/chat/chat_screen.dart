import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService.instance;

  String? _currentUserId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (_sending || text.isEmpty || _currentUserId == null) return;

    _msgController.clear();
    setState(() => _sending = true);

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: _currentUserId!,
        message: text,
      );
    } catch (e) {
      _msgController.text = text;
      _msgController.selection = TextSelection.fromPosition(
        TextPosition(offset: _msgController.text.length),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _chatService.getConversationDetails(widget.conversationId),
          builder: (context, snapshot) {
            String title = 'Chat';
            if (snapshot.hasData && snapshot.data != null) {
              final conv = snapshot.data!;
              final isBuyer = conv['buyer_id'] == _currentUserId;
              final buyer = conv['buyer'] as Map?;
              final seller = conv['seller'] as Map?;
              title = isBuyer
                  ? (seller?['name'] ?? 'Seller')
                  : (buyer?['name'] ?? 'Buyer');
            }
            return Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Messages list ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Unable to load messages right now.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: AppColors.textHint.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start the conversation!',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _currentUserId;
                    return _MessageBubble(
                      text: _messageText(msg),
                      isMe: isMe,
                      timestamp: DateTime.tryParse(
                          msg['created_at']?.toString() ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgController,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_sending) _sendMessage();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageText(Map<String, dynamic> message) {
    final value =
        message['content'] ?? message['message'] ?? message['text'] ?? '';
    return value.toString();
  }
}

// ── Message bubble widget ──────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? timestamp;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(timestamp!),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color:
                      isMe ? Colors.white.withOpacity(0.6) : AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}
