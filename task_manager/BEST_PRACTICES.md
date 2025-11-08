# 🔐 Supabase Best Practices & Security

Ghid pentru a folosi Supabase în mod sigur și eficient.

## 🔒 Securitate

### 1. Protejarea Cheilor

#### ✅ Ce POȚI face:

```dart
// Anon/Public Key poate fi în cod - este sigur
static const String supabaseAnonKey = 'eyJhb...'; // OK!
```

#### ❌ Ce NU TREBUIE să faci:

```dart
// NICIODATĂ nu pune Service Role Key în cod!
// Service Role Key = ACCES COMPLET LA BAZA DE DATE
static const String serviceRoleKey = 'eyJhb...'; // PERICULOS! ❌
```

### 2. Row Level Security (RLS)

**Întotdeauna activează RLS pentru toate tabelele!**

```sql
-- Activează RLS
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;

-- Creează policies pentru fiecare operație
CREATE POLICY "policy_name" ON your_table
  FOR SELECT/INSERT/UPDATE/DELETE
  TO authenticated/anon
  USING (condition);
```

### 3. Validare Date

**Nu te baza doar pe validare client-side!**

```sql
-- Adaugă constraints în baza de date
ALTER TABLE tasks
  ADD CONSTRAINT check_status
  CHECK (status IN ('To Do', 'In Progress', 'Done'));

ALTER TABLE tasks
  ADD CONSTRAINT check_title_not_empty
  CHECK (length(trim(title)) > 0);
```

## ⚡ Performanță

### 1. Indexuri

**Creează indexuri pentru coloane folosite frecvent în WHERE/JOIN:**

```sql
-- Pentru căutare
CREATE INDEX idx_tasks_title ON tasks USING gin(to_tsvector('english', title));

-- Pentru filtrare
CREATE INDEX idx_tasks_status ON tasks(status);

-- Pentru sortare
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);

-- Pentru relații
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
```

### 2. Queries Eficiente

#### ❌ Evită:

```dart
// Nu încărca toate coloanele dacă nu ai nevoie
final response = await supabase.from('tasks').select();
```

#### ✅ Preferă:

```dart
// Selectează doar ce ai nevoie
final response = await supabase
  .from('tasks')
  .select('id, title, status')
  .eq('status', 'To Do')
  .limit(10);
```

### 3. Paginare

**Folosește paginare pentru liste mari:**

```dart
final pageSize = 20;
final page = 0; // 0, 1, 2...

final response = await supabase
  .from('tasks')
  .select()
  .range(page * pageSize, (page + 1) * pageSize - 1);
```

## 🔄 Real-time

### 1. Subscripții Eficiente

#### ❌ Evită subscripții multiple:

```dart
// Nu crea mai multe subscripții pentru același tabel
supabase.from('tasks').on('INSERT', callback1).subscribe();
supabase.from('tasks').on('UPDATE', callback2).subscribe();
```

#### ✅ Folosește o singură subscripție:

```dart
// O subscripție pentru toate evenimentele
final channel = supabase
  .channel('tasks_channel')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'tasks',
    callback: (payload) {
      // Handle all changes
    },
  )
  .subscribe();

// Nu uita să oprești subscripția!
@override
void dispose() {
  supabase.removeChannel(channel);
  super.dispose();
}
```

### 2. Filtrare Real-time

```dart
// Ascultă doar pentru task-uri specifice
final channel = supabase
  .channel('my_tasks')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'tasks',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'created_by',
      value: userId,
    ),
    callback: (payload) {
      // Handle changes only for my tasks
    },
  )
  .subscribe();
```

## 💾 Gestionare Date

### 1. Cascading Deletes

**Definește cum să se comporte ștergerea:**

```sql
-- Șterge toate task-urile când utilizatorul e șters
ALTER TABLE tasks
  DROP CONSTRAINT tasks_created_by_fkey,
  ADD CONSTRAINT tasks_created_by_fkey
    FOREIGN KEY (created_by)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;

-- Setează assigned_to la NULL când utilizatorul e șters
ALTER TABLE tasks
  DROP CONSTRAINT tasks_assigned_to_fkey,
  ADD CONSTRAINT tasks_assigned_to_fkey
    FOREIGN KEY (assigned_to)
    REFERENCES users(id)
    ON DELETE SET NULL;
```

### 2. Soft Delete vs Hard Delete

#### Hard Delete (permanent):

```dart
await supabase.from('tasks').delete().eq('id', taskId);
```

#### Soft Delete (marcaj):

```sql
-- Adaugă coloană deleted_at
ALTER TABLE tasks ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;

-- Filtrează în queries
CREATE VIEW active_tasks AS
  SELECT * FROM tasks WHERE deleted_at IS NULL;
```

```dart
// Marchează ca șters
await supabase.from('tasks')
  .update({'deleted_at': DateTime.now().toIso8601String()})
  .eq('id', taskId);
```

## 🔍 Debugging

### 1. Verificare Errors

```dart
try {
  final response = await supabase.from('tasks').select();
  print('Success: $response');
} on PostgrestException catch (error) {
  print('Database error: ${error.message}');
  print('Code: ${error.code}');
  print('Details: ${error.details}');
} catch (error) {
  print('Unexpected error: $error');
}
```

### 2. Logging Queries

**În Supabase Dashboard:**

- Logs → Database Logs
- Activează Query Performance Insights
- Verifică slow queries

### 3. Testing Policies

```sql
-- Testează ca un utilizator specific
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "user-uuid-here"}';

-- Rulează query pentru a testa
SELECT * FROM tasks;

-- Reset role
RESET ROLE;
```

## 🌍 Environment Variables

### Pentru Production:

1. **Creează fișier `.env`** (nu commit în git!):

```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhb...
```

2. **Adaugă în `.gitignore`**:

```
.env
lib/config/supabase_config.dart
```

3. **Folosește package `flutter_dotenv`**:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load(fileName: ".env");
final supabaseUrl = dotenv.env['SUPABASE_URL']!;
```

## 📊 Monitoring

### 1. Verifică Usage

**În Dashboard:**

- Home → Database Size
- Home → Database Egress
- Authentication → Users (growth)

### 2. Set Alerts

- Database → Settings → Database Webhooks
- Configurează pentru events importante

## 🔄 Backup Strategy

### 1. Automated Backups (Supabase Pro)

- Dashboard → Database → Backups
- Daily automated backups

### 2. Manual Export (Free tier)

```sql
-- Export date în format JSON
SELECT json_agg(row_to_json(t))
FROM (SELECT * FROM tasks) t;
```

## 🚀 Migration Strategy

### 1. Development → Production

1. **Creează un migration file**:

```sql
-- migrations/001_initial_schema.sql
CREATE TABLE tasks (...);
```

2. **Testează în development**
3. **Aplică în production** prin SQL Editor

### 2. Schema Changes

**Întotdeauna:**

- ✅ Adaugă coloane noi cu DEFAULT
- ✅ Testează în development first
- ✅ Backup înainte de changes
- ❌ Nu șterge coloane direct în production

## 🎯 Checklist Launch Production

- [ ] RLS activat pentru toate tabelele
- [ ] Policies configurate și testate
- [ ] Indexuri create pentru queries frecvente
- [ ] Constraints adăugate pentru validare
- [ ] Environment variables configurate
- [ ] Backup strategy implementată
- [ ] Error handling în toate queries
- [ ] Email confirmations activate
- [ ] Rate limiting configurat
- [ ] Monitoring configurat

## 📚 Resurse

- [Supabase Docs](https://supabase.com/docs)
- [PostgreSQL Best Practices](https://www.postgresql.org/docs/current/performance-tips.html)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)
