import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../services/supabase_service.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      await SupabaseService.setOnline();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'حدث خطأ، حاول مرة أخرى');
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 24)
                      ],
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 38),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('مرحباً بك 👋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
                const SizedBox(height: 6),
                Text('سجّل دخولك إلى دردشاتي',
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.55), fontFamily: 'Cairo')),
                const SizedBox(height: 36),
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GlassTextField(
                          controller: _emailCtrl,
                          hint: 'البريد الإلكتروني',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.contains('@') ? null : 'بريد غير صحيح',
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                              validator: (v) => v!.length >= 6 ? null : 'كلمة المرور قصيرة',
                              decoration: InputDecoration(
                                hintText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppTheme.textSecondary, size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.error.withOpacity(0.4)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13, fontFamily: 'Cairo'))),
                            ]),
                          )
                        ],
                        const SizedBox(height: 20),
                        GradientButton(label: 'تسجيل الدخول', onTap: _login, loading: _loading),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Cairo')),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                ]),
                const SizedBox(height: 20),
                // Google button
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFEA4335), Color(0xFF4285F4)]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.g_mobiledata, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('المتابعة مع Google',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Cairo'),
                        children: [
                          TextSpan(text: 'ليس لديك حساب؟ ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                          const TextSpan(text: 'سجّل الآن', style: TextStyle(color: AppTheme.accentAlt, fontSize: 14, fontWeight: FontWeight.w700)),
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
