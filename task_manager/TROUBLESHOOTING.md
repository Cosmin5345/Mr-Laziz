# 🔧 Fix-uri pentru Erori Comune Supabase

## Error: incompatible types integer and uuid

### Problema

```
ERROR: 42804: foreign key constraint "tasks_assigned_to_fkey" cannot be implemented
DETAIL: Key columns "assigned_to" and "id" are of incompatible types: integer and uuid.
```

### Cauza

Tabelul `users` folosește UUID pentru `id`, dar `tasks.assigned_to` era definit ca INTEGER.

### Soluția ✅

Am actualizat schema pentru a folosi UUID:

```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  -- nu INTEGER
);
```

### Modificări în Cod

**Modelul Task:**

```dart
// Înainte ❌
final int? assignedToUserId;

// Acum ✅
final String? assignedTo; // UUID as String
```

**Modelul User:**

```dart
// Înainte ❌
final int id;

// Acum ✅
final String id; // UUID as String
```

**API Service:**

```dart
// Înainte ❌
Future<void> assignTask(int taskId, int? userId)

// Acum ✅
Future<void> assignTask(int taskId, String? userId)
```

---

## Alte Erori Comune

### 1. "relation does not exist"

**Soluție:** Verifică că ai rulat `supabase_setup.sql` complet în SQL Editor.

```sql
-- Verifică tabelele
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';
```

### 2. "permission denied for table"

**Soluție:** Verifică RLS policies.

```sql
-- Verifică că RLS este activat
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public';

-- Listează policies
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

### 3. "new row violates row-level security policy"

**Soluție:** Policy-ul pentru INSERT blochează operația.

```sql
-- Verifică policy pentru INSERT
SELECT * FROM pg_policies
WHERE tablename = 'tasks' AND cmd = 'INSERT';

-- Asigură-te că created_by = auth.uid()
```

### 4. "invalid input syntax for type uuid"

**Cauză:** Încerci să inserezi un integer într-o coloană UUID.

**Soluție:**

```dart
// Folosește UUID-uri (String în Dart)
final userId = supabase.auth.currentUser?.id; // Este String (UUID)
await supabase.from('tasks')
  .insert({'assigned_to': userId}); // Nu converti la int!
```

---

## Checklist Debugging

- [ ] SQL-ul din `supabase_setup.sql` s-a executat fără erori
- [ ] Toate tabelele există în Table Editor
- [ ] RLS este activat pentru toate tabelele
- [ ] Policies există pentru toate operațiile (SELECT, INSERT, UPDATE, DELETE)
- [ ] `supabase_config.dart` are URL și key corecte
- [ ] `flutter pub get` executat cu succes
- [ ] Modelele Dart folosesc tipuri corecte (String pentru UUID)

---

## Cum să Verifici Tipurile de Date

```sql
-- Verifică structura tabelului
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'tasks';

-- Output așteptat:
-- assigned_to | uuid | YES
-- created_by  | uuid | YES
-- id          | integer | NO
```

---

## Resetare Completă (Dacă Nimic Nu Funcționează)

```sql
-- ATENȚIE: Șterge totul!

-- 1. Șterge tabelele
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 2. Șterge funcția și trigger-ul
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- 3. Rulează din nou supabase_setup.sql
```

---

## Teste Rapide

### Test 1: Verifică Conexiunea

```dart
try {
  final count = await Supabase.instance.client
    .from('tasks')
    .select('id', const FetchOptions(count: CountOption.exact))
    .count();
  print('Tasks count: $count');
} catch (e) {
  print('Connection failed: $e');
}
```

### Test 2: Verifică Auth

```dart
final user = Supabase.instance.client.auth.currentUser;
print('User ID: ${user?.id}'); // Trebuie să fie UUID (String)
print('User Email: ${user?.email}');
```

### Test 3: Verifică Inserare

```sql
-- În SQL Editor
INSERT INTO tasks (title, status, created_by)
VALUES (
  'Test Task',
  'To Do',
  auth.uid() -- UUID curent
);

-- Verifică
SELECT * FROM tasks WHERE title = 'Test Task';
```
