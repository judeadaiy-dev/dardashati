class AppUser {
  final String id;
  final String? fullName;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? zodiac;
  final int? age;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? role; // for room context

  AppUser({
    required this.id,
    this.fullName,
    this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.zodiac,
    this.age,
    this.isOnline = false,
    this.lastSeen,
    this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] ?? '',
        fullName: m['full_name'],
        username: m['username'],
        email: m['email'],
        avatarUrl: m['avatar_url'],
        bio: m['bio'],
        zodiac: m['zodiac'],
        age: m['age'],
        isOnline: m['is_online'] ?? false,
        lastSeen: m['last_seen'] != null ? DateTime.tryParse(m['last_seen']) : null,
        role: m['role'],
      );

  AppUser copyWith({String? role}) => AppUser(
        id: id,
        fullName: fullName,
        username: username,
        email: email,
        avatarUrl: avatarUrl,
        bio: bio,
        zodiac: zodiac,
        age: age,
        isOnline: isOnline,
        lastSeen: lastSeen,
        role: role ?? this.role,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'bio': bio,
        'zodiac': zodiac,
        'age': age,
      };
}

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String createdBy;
  final bool isPrivate;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.createdBy,
    this.isPrivate = false,
    this.isActive = false,
    this.updatedAt,
    this.createdAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> m) => ChatRoom(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        description: m['description'],
        avatarUrl: m['avatar_url'],
        createdBy: m['created_by'] ?? '',
        isPrivate: m['is_private'] ?? false,
        isActive: m['is_active'] ?? false,
        updatedAt: m['updated_at'] != null ? DateTime.tryParse(m['updated_at']) : null,
        createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at']) : null,
      );
}

class AppMessage {
  final String id;
  final String? roomId;
  final String? receiverId;
  final String senderId;
  final String content;
  final String type; // text | voice
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? senderName;
  final String? senderAvatar;
  final String? senderUsername;

  AppMessage({
    required this.id,
    this.roomId,
    this.receiverId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.deletedAt,
    this.senderName,
    this.senderAvatar,
    this.senderUsername,
  });

  bool get isDeleted => deletedAt != null;

  factory AppMessage.fromMap(Map<String, dynamic> m) {
    final profile = m['profiles'];
    return AppMessage(
      id: m['id'] ?? '',
      roomId: m['room_id'],
      receiverId: m['receiver_id'],
      senderId: m['sender_id'] ?? '',
      content: m['content'] ?? '',
      type: m['type'] ?? 'text',
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at']) ?? DateTime.now()
          : DateTime.now(),
      deletedAt: m['deleted_at'] != null ? DateTime.tryParse(m['deleted_at']) : null,
      senderName: profile?['full_name'],
      senderAvatar: profile?['avatar_url'],
      senderUsername: profile?['username'],
    );
  }
}
