import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';

class MessageBubble extends StatelessWidget {
  final AppMessage message;
  final bool isMe;
  final VoidCallback? onDelete;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onDelete,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _DeletedBubble(isMe: isMe);
    }
    return GestureDetector(
      onLongPress: isMe ? () => _showOptions(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showAvatar) ...[
              OnlineAvatar(url: message.senderAvatar, name: message.senderName ?? '?', size: 30),
              const SizedBox(width: 8),
            ] else if (!isMe) const SizedBox(width: 38),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(message.senderName ?? '', style: TextStyle(color: AppTheme.accentAlt.withOpacity(0.8), fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                    ),
                  _buildBubble(),
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Text(
                      _formatTime(message.createdAt),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMe ? 18 : 4),
        bottomRight: Radius.circular(isMe ? 4 : 18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            gradient: isMe
                ? AppTheme.accentGradient
                : null,
            color: isMe ? null : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            border: isMe ? null : Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Cairo', height: 1.4)),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageOptions(onDelete: () {
        Navigator.pop(context);
        onDelete?.call();
      }),
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('hh:mm a', 'ar').format(dt.toLocal());
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isMe;

  const _DeletedBubble({required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isMe ? 60 : 0, right: isMe ? 0 : 60, top: 3, bottom: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.not_interested_rounded, size: 14, color: AppTheme.textSecondary),
            SizedBox(width: 6),
            Text('تم حذف الرسالة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'Cairo', fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _MessageOptions extends StatelessWidget {
  final VoidCallback onDelete;

  const _MessageOptions({required this.onDelete});

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
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  ),
                  title: const Text('حذف الرسالة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  onTap: onDelete,
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

// ── Voice Input Bar ──────────────────────────────────────────
class ChatInputBar extends StatefulWidget {
  final void Function(String text) onSendText;
  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceStop;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    this.onVoiceStart,
    this.onVoiceStop,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false;
  bool _recording = false;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withOpacity(0.9),
            border: const Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
          ),
          padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 14),
                      maxLines: 4, minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontFamily: 'Cairo'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _hasText
                    ? () {
                        widget.onSendText(_ctrl.text.trim());
                        _ctrl.clear();
                        setState(() => _hasText = false);
                      }
                    : null,
                onLongPressStart: !_hasText ? (_) {
                  setState(() => _recording = true);
                  widget.onVoiceStart?.call();
                } : null,
                onLongPressEnd: !_hasText ? (_) {
                  setState(() => _recording = false);
                  widget.onVoiceStop?.call();
                } : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: _recording
                        ? const LinearGradient(colors: [AppTheme.error, Color(0xFFFF8C55)])
                        : AppTheme.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_recording ? AppTheme.error : AppTheme.accent).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    _hasText
                        ? Icons.send_rounded
                        : (_recording ? Icons.mic_rounded : Icons.mic_none_rounded),
                    color: Colors.white, size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
