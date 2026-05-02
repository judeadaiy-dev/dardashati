import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _selectedZodiac;
  bool _saving = false;

  final _zodiacs = ['♈ الحمل', '♉ الثور', '♊ الجوزاء', '♋ السرطان', '♌ الأسد', '♍ العذراء',
    '♎ الميزان', '♏ العقرب', '♐ القوس', '♑ الجدي', '♒ الدلو', '♓ الحوت'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await SupabaseService.getProfile(SupabaseService.currentUser!.id);
    if (user != null) {
      setState(() {
        _user = user;
        _nameCtrl.text = user.fullName ?? '';
        _usernameCtrl.text = user.username ?? '';
        _bioCtrl.text = user.bio ?? '';
        _selectedZodiac = user.zodiac;
        _loading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final url = await SupabaseService.uploadAvatar(SupabaseService.currentUser!.id, File(picked.path));
    if (url != null) {
      await SupabaseService.updateProfile(SupabaseService.currentUser!.id, {'avatar_url': url});
      await _load();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await SupabaseService.updateProfile(SupabaseService.currentUser!.id, {
      'full_name': _nameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'zodiac': _selectedZodiac,
    });
    await _load();
    setState(() { _saving = false; _editing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم حفظ التغييرات ✅', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.accentGreen,
      ));
    }
  }

  Future<void> _logout() async {
    await SupabaseService.setOffline();
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(child: _buildAvatarSection()),
                  SliverToBoxAdapter(child: _buildInfoSection()),
                  SliverToBoxAdapter(child: _buildActionButtons()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('حسابي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
            GestureDetector(
              onTap: () => setState(() => _editing = !_editing),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _editing ? null : AppTheme.accentGradient,
                  color: _editing ? AppTheme.glass : null,
                  borderRadius: BorderRadius.circular(12),
                  border: _editing ? Border.all(color: AppTheme.glassBorder) : null,
                ),
                child: Text(_editing ? 'إلغاء' : 'تعديل',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.accentGradient,
                  boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 24)],
                ),
                child: _user?.avatarUrl != null
                    ? ClipOval(child: Image.network(_user!.avatarUrl!, fit: BoxFit.cover))
                    : Center(child: Text((_user?.fullName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bg1, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlassCard(
        child: Column(
          children: [
            if (!_editing) ...[
              _InfoRow(icon: Icons.person_rounded, label: 'الاسم', value: _user?.fullName ?? '-'),
              _InfoRow(icon: Icons.alternate_email_rounded, label: 'اليوزر', value: '@${_user?.username ?? '-'}'),
              _InfoRow(icon: Icons.info_outline_rounded, label: 'النبذة', value: _user?.bio ?? 'لا توجد نبذة'),
              if (_user?.zodiac != null)
                _InfoRow(icon: Icons.star_outline_rounded, label: 'البرج', value: _user!.zodiac!),
              _InfoRow(icon: Icons.email_outlined, label: 'البريد', value: _user?.email ?? '-'),
            ] else ...[
              GlassTextField(controller: _nameCtrl, hint: 'الاسم الكامل', prefixIcon: Icons.person_outline),
              const SizedBox(height: 12),
              GlassTextField(controller: _usernameCtrl, hint: 'اسم المستخدم', prefixIcon: Icons.alternate_email),
              const SizedBox(height: 12),
              GlassTextField(controller: _bioCtrl, hint: 'نبذة عنك...', prefixIcon: Icons.info_outline),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedZodiac,
                hint: const Text('اختر برجك', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                dropdownColor: AppTheme.bg2,
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  filled: true, fillColor: AppTheme.glass,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  prefixIcon: const Icon(Icons.star_outline_rounded, color: AppTheme.textSecondary, size: 20),
                ),
                items: _zodiacs.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: (v) => setState(() => _selectedZodiac = v),
              ),
              const SizedBox(height: 16),
              GradientButton(label: 'حفظ التغييرات', onTap: _saveProfile, loading: _saving),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        child: Column(
          children: [
            _ActionTile(
              icon: Icons.logout_rounded,
              label: 'تسجيل الخروج',
              color: AppTheme.error,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'Cairo')),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
