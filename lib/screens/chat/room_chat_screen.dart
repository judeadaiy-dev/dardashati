import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/message_bubble.dart';
import 'room_info_screen.dart';

class RoomChatScreen extends StatefulWidget {
  final ChatRoom room;

  const RoomChatScreen({super.key, required this.room});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  List<AppMessage> _messages = [];
  bool _loading = true;
  RealtimeChannel? _channel;
  final _scrollCtrl = ScrollController();
  final me = SupabaseService.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    final msgs = await SupabaseService.getMessages(widget.room.id);
    setState(() { _messages = msgs; _loading = false; });
  }

  void _subscribe() {
    _channel = SupabaseService.subscribeToRoom(widget.room.id, (payload) async {
      final newMsg = AppMessage.fromMap(payload.newRecord);
      setState(() => _messages.insert(0, newMsg));
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendText(String text) async {
    if (text.isEmpty) return;
    if (!widget.room.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الغرفة مغلقة ❌', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    await SupabaseService.sendMessage(roomId: widget.room.id, content: text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 44),
            if (!widget.room.isActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: AppTheme.error.withOpacity(0.2),
                child: const Text('⚠️ الغرفة مغلقة - لا يمكن إرسال رسائل', textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 12)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _messages.isEmpty
                      ? Center(child: Text('لا توجد رسائل بعد، ابدأ المحادثة!',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Cairo')))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isMe = msg.senderId == me;
                            return MessageBubble(
                              message: msg,
                              isMe: isMe,
                              showAvatar: !isMe,
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
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
            title: GestureDetector(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RoomInfoScreen(room: widget.room))),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(widget.room.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.room.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: Colors.white)),
                        Text(widget.room.isActive ? '🟢 نشطة' : '🔴 مغلقة',
                            style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RoomInfoScreen(room: widget.room))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
