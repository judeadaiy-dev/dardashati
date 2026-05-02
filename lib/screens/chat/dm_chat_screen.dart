import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/message_bubble.dart';

class DMChatScreen extends StatefulWidget {
  final AppUser user;

  const DMChatScreen({super.key, required this.user});

  @override
  State<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends State<DMChatScreen> {
  List<AppMessage> _messages = [];
  bool _loading = true;
  RealtimeChannel? _channel;
  final me = SupabaseService.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    final msgs = await SupabaseService.getDirectMessages(widget.user.id);
    setState(() { _messages = msgs; _loading = false; });
  }

  void _subscribe() {
    _channel = SupabaseService.subscribeToDMs(widget.user.id, (payload) {
      final newMsg = AppMessage.fromMap(payload.newRecord);
      final relevant = (newMsg.senderId == widget.user.id && newMsg.receiverId == me) ||
          (newMsg.senderId == me && newMsg.receiverId == widget.user.id);
      if (relevant) setState(() => _messages.insert(0, newMsg));
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _sendText(String text) async {
    if (text.isEmpty) return;
    await SupabaseService.sendMessage(receiverId: widget.user.id, content: text);
  }

  Future<void> _deleteMessage(String msgId) async {
    await SupabaseService.deleteMessage(msgId);
    setState(() {
      final i = _messages.indexWhere((m) => m.id == msgId);
      if (i != -1) {
        _messages[i] = AppMessage(
          id: _messages[i].id, senderId: _messages[i].senderId,
          content: '', createdAt: _messages[i].createdAt,
          deletedAt: DateTime.now(),
        );
      }
    });
  }

  void _showUserOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserOptionsSheet(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: const Color(0xFF0D1117).withOpacity(0.8),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  OnlineAvatar(url: widget.user.avatarUrl, name: widget.user.fullName ?? '?', size: 38, isOnline: widget.user.isOnline),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.fullName ?? 'مجهول', style: const TextStyle(fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(widget.user.isOnline ? 'نشط الآن 🟢' : 'غير متاح',
                          style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                  onPressed: _showUserOptions,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 44),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _messages.isEmpty
                      ? Center(child: Text('ابدأ محادثتك الأولى مع ${widget.user.fullName}!',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Cairo')))
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isMe = msg.senderId == me;
                            return MessageBubble(
                              message: msg,
                              isMe: isMe,
                              showAvatar: false,
                              onDelete: isMe ? () => _deleteMessage(msg.id) : null,
                            );
                          },
                        ),
            ),
            ChatInputBar(onSendText: _sendText),
          ],
        ),
      ),
    );
  }
}

class _UserOptionsSheet extends StatelessWidget {
  final AppUser user;

  const _UserOptionsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.block_rounded, color: AppTheme.error)),
                  title: const Text('حظر المستخدم', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  onTap: () async {
                    await SupabaseService.blockUser(user.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.flag_outlined, color: Colors.orange)),
                  title: const Text('إبلاغ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  onTap: () async {
                    await SupabaseService.reportUser(user.id, 'محتوى غير لائق');
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.accentGreen));
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
