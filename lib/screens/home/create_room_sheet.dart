import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';

class CreateRoomSheet extends StatefulWidget {
  const CreateRoomSheet({super.key});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPrivate = false;
  bool _loading = false;
  String? _error;

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.createRoom(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        _isPrivate,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إرسال طلب إنشاء الغرفة للإدارة ✅', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.accentGreen,
        ));
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('إنشاء غرفة جديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
              Text('سيتم مراجعة الطلب من الإدارة', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45), fontFamily: 'Cairo')),
              const SizedBox(height: 20),
              GlassTextField(controller: _nameCtrl, hint: 'اسم الغرفة', prefixIcon: Icons.groups_2_outlined),
              const SizedBox(height: 12),
              GlassTextField(controller: _descCtrl, hint: 'وصف مختصر (اختياري)', prefixIcon: Icons.info_outline),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 18),
                      SizedBox(width: 10),
                      Text('غرفة خاصة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                    ]),
                    Switch(
                      value: _isPrivate,
                      onChanged: (v) => setState(() => _isPrivate = v),
                      activeColor: AppTheme.accent,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
              ],
              const SizedBox(height: 20),
              GradientButton(label: 'إرسال طلب الإنشاء', onTap: _create, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
