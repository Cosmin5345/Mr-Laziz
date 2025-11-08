# 🎬 Tutorial Complet: Task Manager cu Supabase

Ghid pas cu pas pentru a înțelege și folosi aplicația.

---

## 📋 Cuprins

1. [Înțelegerea Arhitecturii](#arhitectura)
2. [Setup Complet](#setup)
3. [Cum Funcționează Authentication](#authentication)
4. [Operații CRUD](#crud)
5. [Real-time Features](#realtime)
6. [Troubleshooting](#troubleshooting)

---

## 🏗️ Arhitectura

### Stack Tehnologic

```
┌─────────────────────────────────────┐
│         Flutter App (Client)         │
│  ┌──────────────────────────────┐   │
│  │  UI Layer (Screens)          │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  Business Logic (Services)   │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  Models (Task, User)         │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
                 ↕️ (HTTP/WebSocket)
┌─────────────────────────────────────┐
│      Supabase (Backend)             │
│  ┌──────────────────────────────┐   │
│  │  Authentication (JWT)        │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  PostgreSQL Database         │   │
│  │    - users table             │   │
│  │    - tasks table             │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  Row Level Security          │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  Real-time Subscriptions     │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Flow-ul Datelor

```
User Action → Flutter UI → Service Layer → Supabase Client →
PostgreSQL → RLS Check → Response → Service → Update UI
```

---

## 🔧 Setup Complet

### Pas 1: Instalare Flutter SDK

```powershell
# Verifică instalarea
flutter doctor

# Output așteptat:
# ✓ Flutter
# ✓ Android toolchain
# ✓ Chrome / Edge (pentru web)
```

### Pas 2: Clone & Install

```powershell
# Clone repository
git clone <your-repo-url>
cd task_manager

# Instalează dependențele
flutter pub get

# Verifică că nu sunt erori
flutter analyze
```

### Pas 3: Supabase Project

**3.1 Creează Proiect:**

- URL: https://supabase.com/dashboard
- Click "New Project"
- Nume: `task-manager-app`
- Parolă: (generează una strong)
- Region: `Europe West (Frankfurt)` sau cel mai apropiat
- Wait ~2 minute pentru setup

**3.2 Setup Database:**

- Click "SQL Editor" (din sidebar)
- "New Query"
- Copy-paste conținutul din `supabase_setup.sql`
- Click "Run" (Ctrl+Enter)
- Verifică: "Success. No rows returned"

**3.3 Obține Credentials:**

- Settings (⚙️) → API
- Copiază:
  - Project URL: `https://xxx.supabase.co`
  - anon public key: `eyJhbGc...` (long string)

**3.4 Configure App:**

```dart
// lib/config/supabase_config.dart
static const String supabaseUrl = 'PASTE_YOUR_URL_HERE';
static const String supabaseAnonKey = 'PASTE_YOUR_KEY_HERE';
```

### Pas 4: Run!

```powershell
flutter run
```

---

## 🔐 Authentication

### Cum Funcționează?

1. **User Sign Up:**

```
User fills form → AuthService.register() →
Supabase.auth.signUp() → PostgreSQL creates user →
Trigger creates profile in users table →
JWT token returned → Saved in secure storage
```

2. **User Login:**

```
User fills form → AuthService.login() →
Supabase.auth.signInWithPassword() →
JWT token validated → Token saved → Redirect to home
```

3. **Session Management:**

```
App starts → Check secure storage for token →
If exists: Validate with Supabase →
If valid: Show home, else: Show auth screen
```

### Code Deep Dive

#### Sign Up

```dart
// lib/services/auth_service.dart
Future<Map<String, dynamic>> register(String username, String password) async {
  final email = username.contains('@')
    ? username
    : '$username@taskboard.app'; // Convert username to email

  final response = await _supabase.auth.signUp(
    email: email,
    password: password,
    data: {'username': username}, // Metadata
  );

  if (response.user != null) {
    await saveToken(response.session!.accessToken);
    return {'success': true};
  }

  return {'success': false, 'message': 'Registration failed'};
}
```

#### Login

```dart
Future<Map<String, dynamic>> login(String username, String password) async {
  final email = username.contains('@')
    ? username
    : '$username@taskboard.app';

  final response = await _supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );

  await saveToken(response.session!.accessToken);
  return {'success': true};
}
```

---

## 📝 Operații CRUD

### Create Task

**Flow:**

```
User clicks "+" → CreateTaskScreen →
User fills form → Click "Create" →
ApiService.createTask() → Supabase insert →
RLS checks: Is user authenticated? →
Insert successful → Returns task →
Navigate back → Refresh list
```

**Code:**

```dart
// lib/services/api_service.dart
Future<Task> createTask(String title, String? description) async {
  final userId = _supabase.auth.currentUser?.id;

  final response = await _supabase
    .from('tasks')
    .insert({
      'title': title,
      'description': description ?? '',
      'status': 'To Do',
      'created_by': userId, // Auto-fill from auth
      'created_at': DateTime.now().toIso8601String(),
    })
    .select()
    .single();

  return Task.fromJson(response);
}
```

### Read Tasks

**Flow:**

```
Screen loads → getTasks() →
Supabase SELECT * FROM tasks →
RLS checks policies → Returns data →
Map to Task objects → Display in UI
```

**Code:**

```dart
Future<List<Task>> getTasks() async {
  final response = await _supabase
    .from('tasks')
    .select()
    .order('created_at', ascending: false); // Newest first

  return (response as List)
    .map((json) => Task.fromJson(json))
    .toList();
}
```

### Update Task Status (Drag & Drop)

**Flow:**

```
User drags task → onDragCompleted() →
updateTaskStatus(taskId, newStatus) →
Supabase UPDATE tasks SET status=? WHERE id=? →
RLS checks → Update successful →
UI updates optimistically
```

**Code:**

```dart
Future<void> updateTaskStatus(int taskId, String newStatus) async {
  await _supabase
    .from('tasks')
    .update({'status': newStatus})
    .eq('id', taskId);
}
```

### Delete Task

**Flow:**

```
User clicks delete → Confirmation dialog →
deleteTask(taskId) → Supabase DELETE →
RLS checks: Is user the creator? →
Delete successful → Remove from UI
```

**Code:**

```dart
Future<void> deleteTask(int taskId) async {
  await _supabase
    .from('tasks')
    .delete()
    .eq('id', taskId);
}
```

---

## ⚡ Real-time Features

### Setup Subscription

**Flow:**

```
Screen loads → subscribeToTasks() →
Create WebSocket channel →
Subscribe to table changes →
Listen for INSERT/UPDATE/DELETE →
When change detected → Reload tasks → Update UI
```

**Code:**

```dart
// lib/services/api_service.dart
RealtimeChannel subscribeToTasks(Function(List<Task>) onTasksChanged) {
  return _supabase
    .channel('tasks_channel')
    .onPostgresChanges(
      event: PostgresChangeEvent.all, // INSERT, UPDATE, DELETE
      schema: 'public',
      table: 'tasks',
      callback: (payload) async {
        // Change detected! Reload all tasks
        final tasks = await getTasks();
        onTasksChanged(tasks); // Notify UI
      },
    )
    .subscribe();
}
```

### Using in Screen

```dart
// lib/screens/task_board_screen.dart
RealtimeChannel? _taskChannel;

@override
void initState() {
  super.initState();
  _loadTasks();
  _setupRealtimeSubscription();
}

void _setupRealtimeSubscription() {
  _taskChannel = _apiService.subscribeToTasks((updatedTasks) {
    setState(() {
      _tasks = updatedTasks;
    });
  });
}

@override
void dispose() {
  _apiService.unsubscribe(_taskChannel!);
  super.dispose();
}
```

---

## 🔍 Troubleshooting

### Problem 1: "Connection failed"

**Symptoms:**

- App shows "Network error"
- Can't login/register

**Solutions:**

```dart
// 1. Verifică config
print(SupabaseConfig.supabaseUrl); // Should be https://xxx.supabase.co
print(SupabaseConfig.supabaseAnonKey); // Should be long string

// 2. Test connection manual
try {
  final response = await Supabase.instance.client
    .from('tasks')
    .select()
    .limit(1);
  print('Connection OK: $response');
} catch (e) {
  print('Connection FAILED: $e');
}

// 3. Verifică în Supabase Dashboard
// Settings → API → Verifică că URL și Key sunt corecte
```

### Problem 2: "Authentication failed"

**Symptoms:**

- Sign up/Login fails
- "Invalid credentials" error

**Solutions:**

```sql
-- 1. Verifică în Supabase Dashboard:
-- Authentication → Settings → Email Auth MUST be enabled

-- 2. Check user exists
SELECT * FROM auth.users WHERE email LIKE '%username%';

-- 3. Reset password (în Dashboard):
-- Authentication → Users → Click user → Send Password Reset
```

### Problem 3: "Tasks not loading"

**Symptoms:**

- Empty screen after login
- "Failed to load tasks" error

**Solutions:**

```sql
-- 1. Verifică că tabelul există
SELECT * FROM tasks LIMIT 1;

-- 2. Verifică RLS policies
SELECT * FROM pg_policies WHERE tablename = 'tasks';

-- 3. Test policy manual
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "user-uuid"}';
SELECT * FROM tasks;

-- 4. Adaugă task manual pentru test
INSERT INTO tasks (title, status, created_by)
VALUES ('Test', 'To Do', 'user-uuid-from-auth-users');
```

### Problem 4: "Real-time not working"

**Symptoms:**

- Changes don't appear automatically
- Need to refresh manually

**Solutions:**

```sql
-- 1. Verifică că Realtime este activat pentru tabel
-- Dashboard → Database → Replication →
-- Enable for 'tasks' table

-- 2. Check în cod că subscription există
print(_taskChannel); // Should NOT be null

-- 3. Test event
-- Adaugă task manual în Supabase Dashboard
-- Ar trebui să apară instant în app
```

---

## 🎓 Concepte Avansate

### Row Level Security (RLS)

**Ce este?**

- Security layer în PostgreSQL
- Filtrează rândurile pe care userul le poate vedea/modifica
- Rulează ÎNAINTEA oricărei operații

**Exemplu:**

```sql
-- Policy: Users can only see their own tasks
CREATE POLICY "Users can view own tasks"
ON tasks FOR SELECT
TO authenticated
USING (created_by = auth.uid());

-- Când user face SELECT:
SELECT * FROM tasks; -- User vede doar task-urile sale

-- PostgreSQL transformă automat în:
SELECT * FROM tasks WHERE created_by = 'current-user-uuid';
```

### JWT Tokens

**Ce conține:**

```json
{
  "sub": "user-uuid", // User ID
  "email": "user@example.com",
  "role": "authenticated",
  "iat": 1234567890, // Issued at
  "exp": 1234571490 // Expires
}
```

**Flow:**

```
1. Login → Supabase generates JWT
2. App saves JWT in secure storage
3. Every request includes: Authorization: Bearer <JWT>
4. Supabase validates JWT
5. If valid → Process request
   If invalid → 401 Unauthorized
```

---

## 🚀 Next Steps

1. **Add Features:**

   - Comments on tasks
   - Task priorities
   - Due dates
   - File attachments

2. **Improve UI:**

   - Animations
   - Dark mode
   - Better drag & drop

3. **Deploy:**

   - Build release APK
   - Deploy to Play Store
   - Setup web hosting

4. **Monitor:**
   - Setup error tracking (Sentry)
   - Analytics (Firebase)
   - Performance monitoring

---

## 📚 Resurse

- **Flutter:** https://docs.flutter.dev/
- **Supabase:** https://supabase.com/docs
- **PostgreSQL:** https://www.postgresql.org/docs/
- **Dart:** https://dart.dev/guides

**Gata! Acum știi cum funcționează totul! 🎉**
