import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../chat/dm_chat_screen.dart';

class DMsTab extends StatefulWidget {
  const DMsTab({super.key});

  @override
  State<DMsTab> createState() => _DMsTabState();
}

class _DMsTabState extends State<DMsTab> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await SupabaseService.getDirectConversations();
      setState(() => _users = users);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المحادثات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppTheme.glass, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.glassBorder)),
                    child: const Icon(Icons.search_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 6,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassShimmer(width: double.infinity, height: 68),
                      ),
                    )
                  : _users.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.chat_outlined, size: 56, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text('لا توجد محادثات بعد', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Cairo')),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _users.length,
                            itemBuilder: (_, i) => _DMCard(
                              user: _users[i],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DMChatScreen(user: _users[i]))),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DMCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _DMCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  OnlineAvatar(url: user.avatarUrl, name: user.fullName ?? '?', size: 50, isOnline: user.isOnline),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName ?? 'مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Cairo')),
                        const SizedBox(height: 3),
                        Text('@${user.username ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  Text(user.isOnline ? 'نشط الآن' : 'غير متاح',
                      style: TextStyle(
                        color: user.isOnline ? AppTheme.accentGreen : AppTheme.textSecondary,
                        fontSize: 11, fontFamily: 'Cairo',
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
