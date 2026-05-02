# دردشاتي - Dardashati Chat App

تطبيق دردشة حديث بتصميم زجاجي (Glassmorphism) مبني بـ Flutter ومربوط بـ Supabase.

---

## 🚀 تشغيل المشروع

```bash
# 1. تثبيت الحزم
flutter pub get

# 2. تشغيل التطبيق
flutter run

# 3. بناء APK
flutter build apk --release
```

---

## 🗄️ جداول Supabase المطلوبة

انسخ وشغّل هذا الـ SQL في **Supabase SQL Editor**:

```sql
-- ── Profiles ──────────────────────────────────────────────
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  username text unique,
  email text,
  avatar_url text,
  bio text,
  zodiac text,
  age int,
  is_online boolean default false,
  last_seen timestamptz,
  created_at timestamptz default now()
);

-- ── Rooms ─────────────────────────────────────────────────
create table if not exists rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  avatar_url text,
  created_by uuid references profiles(id),
  is_private boolean default false,
  is_active boolean default false,   -- يتحكم بها الأدمن
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── Room Members ──────────────────────────────────────────
create table if not exists room_members (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  role text default 'member',        -- 'admin' | 'member'
  joined_at timestamptz default now(),
  unique(room_id, user_id)
);

-- ── Messages ──────────────────────────────────────────────
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  receiver_id uuid references profiles(id),  -- للرسائل المباشرة
  sender_id uuid references profiles(id) on delete cascade,
  content text not null,
  type text default 'text',          -- 'text' | 'voice'
  created_at timestamptz default now(),
  deleted_at timestamptz             -- soft delete
);

-- ── Reports ───────────────────────────────────────────────
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles(id),
  reported_id uuid references profiles(id),
  reason text,
  created_at timestamptz default now()
);

-- ── Blocks ────────────────────────────────────────────────
create table if not exists blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid references profiles(id),
  blocked_id uuid references profiles(id),
  created_at timestamptz default now(),
  unique(blocker_id, blocked_id)
);

-- ── Storage Bucket ────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict do nothing;

-- ── RLS Policies ─────────────────────────────────────────
alter table profiles enable row level security;
alter table rooms enable row level security;
alter table room_members enable row level security;
alter table messages enable row level security;
alter table reports enable row level security;
alter table blocks enable row level security;

-- Profiles
create policy "profiles_select" on profiles for select using (true);
create policy "profiles_insert" on profiles for insert with check (auth.uid() = id);
create policy "profiles_update" on profiles for update using (auth.uid() = id);

-- Rooms
create policy "rooms_select" on rooms for select using (true);
create policy "rooms_insert" on rooms for insert with check (auth.role() = 'authenticated');
create policy "rooms_update" on rooms for update using (
  exists (select 1 from room_members where room_id = id and user_id = auth.uid() and role = 'admin')
);

-- Room Members
create policy "members_select" on room_members for select using (true);
create policy "members_insert" on room_members for insert with check (auth.role() = 'authenticated');
create policy "members_delete" on room_members for delete using (
  user_id = auth.uid() or
  exists (select 1 from room_members m where m.room_id = room_id and m.user_id = auth.uid() and m.role = 'admin')
);

-- Messages
create policy "messages_select" on messages for select using (
  room_id is not null or sender_id = auth.uid() or receiver_id = auth.uid()
);
create policy "messages_insert" on messages for insert with check (sender_id = auth.uid());
create policy "messages_update" on messages for update using (sender_id = auth.uid());

-- Reports & Blocks
create policy "reports_insert" on reports for insert with check (reporter_id = auth.uid());
create policy "blocks_all" on blocks for all using (blocker_id = auth.uid());

-- Storage
create policy "avatars_all" on storage.objects for all using (bucket_id = 'avatars');

-- Realtime
alter publication supabase_realtime add table messages;
alter publication supabase_realtime add table profiles;
```

---

## 🎨 الميزات

| الميزة | الوصف |
|--------|-------|
| 🔐 تسجيل الدخول | بريد + كلمة مرور أو Google |
| 💬 الغرف | غرف عامة/خاصة مع نظام موافقة الأدمن |
| 📩 رسائل مباشرة | محادثات فردية مع مؤشر النشاط |
| 🗑️ حذف الرسائل | soft delete مع ظهور "تم حذف الرسالة" |
| 🎙️ صوتيات | ضغط طويل لتسجيل رسالة صوتية |
| 👤 الملف الشخصي | اسم، يوزر، نبذة، برج، صورة |
| 🛡️ إدارة الغرف | تفعيل/إغلاق، طرد الأعضاء، تغيير صورة |
| 🔴 حظر وإبلاغ | يُرسَل للسوبابيس مباشرة |
| 🟢 مؤشر النشاط | يظهر "نشط الآن" للمستخدمين المتصلين |
| 🪟 تصميم زجاجي | Glassmorphism + ألوان متدرجة + أيقونات متحركة |

---

## 📁 هيكل المشروع

```
lib/
├── main.dart
├── utils/
│   └── app_theme.dart
├── models/
│   └── app_models.dart
├── services/
│   └── supabase_service.dart
├── widgets/
│   ├── glass_widgets.dart
│   └── message_bubble.dart
└── screens/
    ├── splash_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   ├── rooms_tab.dart
    │   ├── dms_tab.dart
    │   └── create_room_sheet.dart
    ├── chat/
    │   ├── room_chat_screen.dart
    │   ├── dm_chat_screen.dart
    │   └── room_info_screen.dart
    └── profile/
        └── profile_screen.dart
```

---

## ⚙️ متطلبات

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android: API 21+
- iOS: 12.0+

بالتوفيق! 🚀
