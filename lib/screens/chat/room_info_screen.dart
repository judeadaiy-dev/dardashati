import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';

class RoomInfoScreen extends StatefulWidget {
  final ChatRoom room;

  const RoomInfoScreen({super.key, required this.room});

  @override
  State<RoomInfoScreen> createState() => _RoomInfoScreenState();
}

class _RoomInfoScreenState extends State<RoomInfoScreen> {
  List<AppUser> _members = [];
  bool _loading = true;
  late bool _isActive;
  final me = SupabaseService.currentUser!.id;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.room.isActive;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await SupabaseService.getRoomMembers(widget.room.id);
    setState(() {
      _members = members;
      _isAdmin = members.any((m) => m.id == me && m.role == 'admin');
      _loading = false;
    });
  }

  Future<void> _toggleStatus() async {
    await SupabaseService.updateRoomStatus(widget.room.id, !_isActive);
    setState(() => _isActive = !_isActive);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isActive ? 'تم تفعيل الغرفة ✅' : 'تم إغلاق الغرفة 🔴', style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: _isActive ? AppTheme.accentGreen : AppTheme.error,
    ));
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final url = await SupabaseService.uploadRoomAvatar(widget.room.id, File(picked.path));
    if (url != null) await SupabaseService.updateRoomAvatar(widget.room.id, url);
    setState(() {});
  }

  Future<void> _kickMember(String userId) async {
    await SupabaseService.kickMember(widget.room.id, userId);
    await _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(child: _buildStats()),
              if (_isAdmin) SliverToBoxAdapter(child: _buildAdminControls()),
              SliverToBoxAdapter(child: _buildMembersTitle()),
              _buildMembersList(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(child: Text('معلومات الغرفة', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo'))),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          children: [
            GestureDetector(
              onTap: _isAdmin ? _changeAvatar : null,
              child: Stack(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: widget.room.avatarUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.network(widget.room.avatarUrl!, fit: BoxFit.cover))
                        : Center(child: Text(widget.room.name[0], style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold))),
                  ),
                  if (_isAdmin)
                    Positioned(bottom: 0, right: 0, child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle, border: Border.all(color: AppTheme.bg1, width: 1.5)),
                      child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                    )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.room.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
            if (widget.room.description != null)
              Text(widget.room.description!, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(label: 'الأعضاء', value: '${_members.length}', icon: Icons.people_rounded),
                _Stat(label: 'الحالة', value: _isActive ? 'نشطة' : 'مغلقة', icon: Icons.circle, color: _isActive ? AppTheme.accentGreen : AppTheme.error),
                _Stat(label: 'النوع', value: widget.room.isPrivate ? 'خاصة' : 'عامة', icon: widget.room.isPrivate ? Icons.lock_rounded : Icons.public_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لوحة الإدارة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(_isActive ? Icons.check_circle_outline : Icons.cancel_outlined, color: _isActive ? AppTheme.accentGreen : AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Text(_isActive ? 'الغرفة مفعّلة' : 'الغرفة مغلقة', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ]),
                Switch(
                  value: _isActive,
                  onChanged: (_) => _toggleStatus(),
                  activeColor: AppTheme.accentGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text('الأعضاء (${_members.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
    );
  }

  Widget _buildMembersList() {
    if (_loading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassShimmer(width: double.infinity, height: 60),
          ))),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final member = _members[i];
          final isCurrentUser = member.id == me;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  OnlineAvatar(url: member.avatarUrl, name: member.fullName ?? '?', size: 42, isOnline: member.isOnline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(member.fullName ?? 'مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                        if (member.role == 'admin') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(6)),
                            child: const Text('أدمن', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'Cairo')),
                          ),
                        ],
                      ]),
                      Text('@${member.username ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
                    ]),
                  ),
                  if (_isAdmin && !isCurrentUser && member.role != 'admin')
                    GestureDetector(
                      onTap: () => _kickMember(member.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.person_remove_outlined, color: AppTheme.error, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        childCount: _members.length,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _Stat({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.accent, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'Cairo')),
      ],
    );
  }
}
