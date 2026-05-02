import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../chat/room_chat_screen.dart';
import 'create_room_sheet.dart';

class RoomsTab extends StatefulWidget {
  const RoomsTab({super.key});

  @override
  State<RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<RoomsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<ChatRoom> _myRooms = [];
  List<ChatRoom> _publicRooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final my = await SupabaseService.getRooms();
      final pub = await SupabaseService.getPublicRooms();
      setState(() { _myRooms = my; _publicRooms = pub; });
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
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildRoomList(_myRooms),
                  _buildRoomList(_publicRooms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('الغرف', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Cairo')),
          GestureDetector(
            onTap: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreateRoomSheet(),
              );
              _load();
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GlassCard(
        padding: const EdgeInsets.all(4),
        borderRadius: 14,
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'غرفي'), Tab(text: 'عامة')],
        ),
      ),
    );
  }

  Widget _buildRoomList(List<ChatRoom> rooms) {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassShimmer(width: double.infinity, height: 72),
        ),
      );
    }
    if (rooms.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.groups_2_outlined, size: 56, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('لا توجد غرف بعد', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Cairo')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: rooms.length,
        itemBuilder: (_, i) => _RoomCard(room: rooms[i], onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RoomChatScreen(room: rooms[i])));
        }),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.onTap});

  Color get _color {
    final colors = [AppTheme.accent, AppTheme.accentAlt, AppTheme.accentGreen,
      const Color(0xFFFF6B9D), const Color(0xFFFFAA00)];
    return colors[room.name.hashCode.abs() % colors.length];
  }

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
                  Stack(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [_color.withOpacity(0.8), _color]),
                        ),
                        child: room.avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(room.avatarUrl!, fit: BoxFit.cover),
                              )
                            : Center(child: Text(room.name[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: room.isActive ? AppTheme.accentGreen : AppTheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.bg1, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(room.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Cairo'), overflow: TextOverflow.ellipsis)),
                            if (room.isPrivate)
                              const Icon(Icons.lock_rounded, color: AppTheme.textSecondary, size: 14),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          room.description ?? (room.isActive ? '🟢 نشطة' : '🔴 مغلقة'),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
