-- ================================================
-- QUERIES UTILE PENTRU SUPABASE
-- ================================================
-- Folosește aceste query-uri în SQL Editor pentru debugging și management

-- ================================================
-- 1. VERIFICARE SETUP
-- ================================================

-- Verifică versiunea PostgreSQL
SELECT version();

-- Listează toate tabelele
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verifică că RLS este activat
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Listează toate policies
SELECT schemaname, tablename, policyname, cmd, permissive, roles, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ================================================
-- 2. VERIFICARE DATE
-- ================================================

-- Număr de utilizatori înregistrați (din auth)
SELECT COUNT(*) as total_users 
FROM auth.users;

-- Număr de utilizatori în tabelul users
SELECT COUNT(*) as total_users 
FROM users;

-- Număr de task-uri per status
SELECT status, COUNT(*) as count 
FROM tasks 
GROUP BY status
ORDER BY count DESC;

-- Toate task-urile cu detalii utilizator
SELECT 
  t.id,
  t.title,
  t.status,
  t.created_at,
  u_creator.username as created_by_username,
  u_assigned.username as assigned_to_username
FROM tasks t
LEFT JOIN auth.users au ON t.created_by = au.id
LEFT JOIN users u_creator ON au.id::text = u_creator.id::text
LEFT JOIN users u_assigned ON t.assigned_to = u_assigned.id
ORDER BY t.created_at DESC;

-- ================================================
-- 3. STATISTICI
-- ================================================

-- Task-uri per utilizator (creator)
SELECT 
  u.username,
  COUNT(t.id) as total_tasks,
  COUNT(CASE WHEN t.status = 'Done' THEN 1 END) as completed_tasks,
  COUNT(CASE WHEN t.status = 'In Progress' THEN 1 END) as in_progress_tasks,
  COUNT(CASE WHEN t.status = 'To Do' THEN 1 END) as todo_tasks
FROM users u
LEFT JOIN auth.users au ON u.id::text = au.id::text
LEFT JOIN tasks t ON t.created_by = au.id
GROUP BY u.username
ORDER BY total_tasks DESC;

-- Task-uri recent create (ultimele 10)
SELECT 
  t.id,
  t.title,
  t.status,
  t.created_at,
  u.username as created_by
FROM tasks t
JOIN auth.users au ON t.created_by = au.id
JOIN users u ON au.id::text = u.id::text
ORDER BY t.created_at DESC
LIMIT 10;

-- Task-uri recent modificate
SELECT 
  t.id,
  t.title,
  t.status,
  t.updated_at,
  u.username as created_by
FROM tasks t
JOIN auth.users au ON t.created_by = au.id
JOIN users u ON au.id::text = u.id::text
ORDER BY t.updated_at DESC
LIMIT 10;

-- ================================================
-- 4. DEBUGGING - VERIFICARE UTILIZATORI
-- ================================================

-- Toți utilizatorii cu email și username
SELECT 
  au.id,
  au.email,
  au.created_at as auth_created_at,
  u.username,
  u.created_at as profile_created_at
FROM auth.users au
LEFT JOIN users u ON au.id::text = u.id::text
ORDER BY au.created_at DESC;

-- Utilizatori fără profil (ar trebui să fie 0)
SELECT au.id, au.email, au.created_at
FROM auth.users au
LEFT JOIN users u ON au.id::text = u.id::text
WHERE u.id IS NULL;

-- ================================================
-- 5. CURĂȚARE DATE (FOLOSEȘTE CU GRIJĂ!)
-- ================================================

-- ATENȚIE: Acestea șterg date permanent!

-- Șterge toate task-urile
-- DELETE FROM tasks;

-- Șterge toți utilizatorii din tabelul users
-- DELETE FROM users;

-- Șterge toți utilizatorii din auth (FOARTE PERICULOS!)
-- DELETE FROM auth.users;

-- Reset ID-uri auto-increment pentru tasks
-- ALTER SEQUENCE tasks_id_seq RESTART WITH 1;

-- ================================================
-- 6. DATE DE TEST
-- ================================================

-- Inserează task-uri de test pentru utilizatorul curent
-- Înlocuiește 'YOUR-USER-UUID' cu UUID-ul tău real din auth.users

/*
INSERT INTO tasks (title, description, status, created_by) VALUES
  ('Review pull requests', 'Check and approve pending PRs', 'To Do', 'YOUR-USER-UUID'),
  ('Update documentation', 'Add new features to docs', 'In Progress', 'YOUR-USER-UUID'),
  ('Fix bug #123', 'Resolve issue with login', 'Done', 'YOUR-USER-UUID'),
  ('Design new feature', 'Create mockups for dashboard', 'To Do', 'YOUR-USER-UUID'),
  ('Write unit tests', 'Add tests for auth service', 'In Progress', 'YOUR-USER-UUID');
*/

-- ================================================
-- 7. OPTIMIZARE PERFORMANȚĂ
-- ================================================

-- Verifică indexurile existente
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Statistici despre tabel (mărime, număr de rânduri)
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  pg_stat_get_tuples_returned(c.oid) as tuple_read,
  pg_stat_get_tuples_fetched(c.oid) as tuple_fetched
FROM pg_tables t
JOIN pg_class c ON t.tablename = c.relname
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ================================================
-- 8. MANAGEMENT UTILIZATORI
-- ================================================

-- Schimbă username pentru un utilizator
-- UPDATE users SET username = 'new_username' WHERE id = 'USER-UUID';

-- Găsește UUID-ul utilizatorului după email
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'user@example.com';

-- Găsește UUID-ul utilizatorului după username
SELECT u.id, u.username, au.email 
FROM users u
JOIN auth.users au ON u.id::text = au.id::text
WHERE u.username = 'username_cautat';

-- ================================================
-- 9. VERIFICARE REAL-TIME SETUP
-- ================================================

-- Verifică că publicarea este activată pentru tabel
SELECT 
  schemaname,
  tablename,
  tableowner,
  hasindexes,
  hasrules,
  hastriggers
FROM pg_tables
WHERE schemaname = 'public';

-- ================================================
-- 10. BACKUP / EXPORT
-- ================================================

-- Export toate task-urile în format JSON
SELECT json_agg(t) 
FROM (
  SELECT * FROM tasks ORDER BY id
) t;

-- Export toți utilizatorii în format JSON
SELECT json_agg(u) 
FROM (
  SELECT * FROM users ORDER BY created_at
) u;

-- ================================================
-- NOTE IMPORTANTE
-- ================================================
-- 1. Folosește queries de ștergere doar în development
-- 2. Întotdeauna fă backup înainte de modificări majore
-- 3. Testează queries pe date de test înainte de production
-- 4. Verifică policies înainte de a face modificări în schema
-- ================================================
