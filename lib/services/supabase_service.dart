import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // ── Auth ────────────────────────────────────────────────
  static Future<AuthResponse> signUp(
      String email, String password, String name, String username) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'username': username},
    );
    if (res.user != null) {
      await supabase.from('profiles').upsert({
        'id': res.user!.id,
        'full_name': name,
        'username': username,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return res;
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
        email: email, password: password);
  }

  static Future<void> signOut() async => await supabase.auth.signOut();

  static User? get currentUser => supabase.auth.currentUser;

  // ── Profile ─────────────────────────────────────────────
  static Future<AppUser?> getProfile(String userId) async {
    final data =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    return data != null ? AppUser.fromMap(data) : null;
  }

  static Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    await supabase.from('profiles').update(data).eq('id', userId);
  }

  static Future<String?> uploadAvatar(String userId, File file) async {
    final ext = file.path.split('.').last;
    final path = 'avatars/$userId.$ext';
    await supabase.storage.from('avatars').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  static Future<String?> uploadRoomAvatar(String roomId, File file) async {
    final ext = file.path.split('.').last;
    final path = 'rooms/$roomId.$ext';
    await supabase.storage.from('avatars').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ── Rooms ────────────────────────────────────────────────
  static Future<List<ChatRoom>> getRooms() async {
    final data = await supabase
        .from('rooms')
        .select('*, room_members!inner(user_id)')
        .eq('room_members.user_id', currentUser!.id)
        .order('updated_at', ascending: false);
    return (data as List).map((e) => ChatRoom.fromMap(e)).toList();
  }

  static Future<List<ChatRoom>> getPublicRooms() async {
    final data = await supabase
        .from('rooms')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ChatRoom.fromMap(e)).toList();
  }

  static Future<ChatRoom?> createRoom(
      String name, String? description, bool isPrivate) async {
    final data = await supabase
        .from('rooms')
        .insert({
          'name': name,
          'description': description,
          'created_by': currentUser!.id,
          'is_private': isPrivate,
          'is_active': false, // needs admin approval
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    // add creator as admin member
    await supabase.from('room_members').insert({
      'room_id': data['id'],
      'user_id': currentUser!.id,
      'role': 'admin',
      'joined_at': DateTime.now().toIso8601String(),
    });
    return ChatRoom.fromMap(data);
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final data = await supabase
        .from('room_members')
        .select('profiles(*), role')
        .eq('room_id', roomId);
    return (data as List).map((e) {
      final u = AppUser.fromMap(e['profiles']);
      return u.copyWith(role: e['role']);
    }).toList();
  }

  static Future<void> joinRoom(String roomId) async {
    await supabase.from('room_members').insert({
      'room_id': roomId,
      'user_id': currentUser!.id,
      'role': 'member',
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> leaveRoom(String roomId) async {
    await supabase
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', currentUser!.id);
  }

  static Future<void> kickMember(String roomId, String userId) async {
    await supabase
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  static Future<void> updateRoomStatus(String roomId, bool isActive) async {
    await supabase
        .from('rooms')
        .update({'is_active': isActive}).eq('id', roomId);
  }

  static Future<void> updateRoomAvatar(String roomId, String url) async {
    await supabase
        .from('rooms')
        .update({'avatar_url': url}).eq('id', roomId);
  }

  // ── Messages ─────────────────────────────────────────────
  static Future<List<AppMessage>> getMessages(String roomId,
      {int limit = 50}) async {
    final data = await supabase
        .from('messages')
        .select('*, profiles(full_name, avatar_url, username)')
        .eq('room_id', roomId)
        .is_('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => AppMessage.fromMap(e)).toList();
  }

  static Future<List<AppMessage>> getDirectMessages(
      String otherUserId) async {
    final me = currentUser!.id;
    final data = await supabase
        .from('messages')
        .select('*, profiles(full_name, avatar_url, username)')
        .or('and(sender_id.eq.$me,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$me)')
        .is_('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => AppMessage.fromMap(e)).toList();
  }

  static Future<AppMessage> sendMessage(
      {String? roomId,
      String? receiverId,
      required String content,
      String type = 'text'}) async {
    final data = await supabase
        .from('messages')
        .insert({
          'room_id': roomId,
          'receiver_id': receiverId,
          'sender_id': currentUser!.id,
          'content': content,
          'type': type,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('*, profiles(full_name, avatar_url, username)')
        .single();
    return AppMessage.fromMap(data);
  }

  static Future<void> deleteMessage(String messageId) async {
    await supabase.from('messages').update(
        {'deleted_at': DateTime.now().toIso8601String()}).eq('id', messageId);
  }

  static RealtimeChannel subscribeToRoom(
      String roomId, void Function(dynamic) onMessage) {
    return supabase
        .channel('room:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId),
          callback: (payload) => onMessage(payload),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToDMs(
      String otherUserId, void Function(dynamic) onMessage) {
    final me = currentUser!.id;
    return supabase
        .channel('dm:${me}_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) => onMessage(payload),
        )
        .subscribe();
  }

  // ── Direct conversations list ────────────────────────────
  static Future<List<AppUser>> getDirectConversations() async {
    final me = currentUser!.id;
    final data = await supabase
        .from('messages')
        .select('sender_id, receiver_id, profiles!messages_sender_id_fkey(id, full_name, avatar_url, username)')
        .or('sender_id.eq.$me,receiver_id.eq.$me')
        .not('receiver_id', 'is', null)
        .order('created_at', ascending: false);
    final seen = <String>{};
    final users = <AppUser>[];
    for (final row in (data as List)) {
      final otherId = row['sender_id'] == me ? row['receiver_id'] : row['sender_id'];
      if (!seen.contains(otherId)) {
        seen.add(otherId);
        users.add(AppUser.fromMap(row['profiles']));
      }
    }
    return users;
  }

  // ── Reports / Block ──────────────────────────────────────
  static Future<void> reportUser(
      String reportedId, String reason) async {
    await supabase.from('reports').insert({
      'reporter_id': currentUser!.id,
      'reported_id': reportedId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> blockUser(String blockedId) async {
    await supabase.from('blocks').insert({
      'blocker_id': currentUser!.id,
      'blocked_id': blockedId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Presence ─────────────────────────────────────────────
  static Future<void> setOnline() async {
    await supabase.from('profiles').update({
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', currentUser!.id);
  }

  static Future<void> setOffline() async {
    await supabase.from('profiles').update({
      'is_online': false,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', currentUser!.id);
  }
}
