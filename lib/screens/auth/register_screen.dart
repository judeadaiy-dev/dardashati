import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../services/supabase_service.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _nameCtrl.text.trim(),
        _usernameCtrl.text.trim(),
      );
      await SupabaseService.setOnline();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                const Text('إنشاء حساب جديد ✨',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
                const SizedBox(height: 6),
                Text('أنضم إلى دردشاتي اليوم',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Cairo')),
                const SizedBox(height: 28),
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GlassTextField(
                          controller: _nameCtrl,
                          hint: 'الاسم الكامل',
                          prefixIcon: Icons.person_outline,
                          validator: (v) => v!.length >= 2 ? null : 'الاسم قصير',
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          controller: _usernameCtrl,
                          hint: 'اسم المستخدم (@username)',
                          prefixIcon: Icons.alternate_email,
                          validator: (v) => v!.length >= 3 ? null : 'يوزر قصير',
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          controller: _emailCtrl,
                          hint: 'البريد الإلكتروني',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.contains('@') ? null : 'بريد غير صحيح',
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          controller: _passCtrl,
                          hint: 'كلمة المرور',
                          prefixIcon: Icons.lock_outline,
                          obscure: _obscure,
                          validator: (v) => v!.length >= 6 ? null : 'كلمة المرور 6 أحرف على الأقل',
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 13)),
                          )
                        ],
                        const SizedBox(height: 20),
                        GradientButton(label: 'إنشاء الحساب', onTap: _register, loading: _loading),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Cairo'),
                        children: [
                          TextSpan(text: 'لديك حساب بالفعل؟ ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                          const TextSpan(text: 'سجّل دخولك', style: TextStyle(color: AppTheme.accentAlt, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
