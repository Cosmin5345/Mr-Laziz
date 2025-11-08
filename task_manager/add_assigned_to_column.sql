-- Migrare: Adaugă coloana assigned_to în tabelul tasks
-- Rulează acest script în Supabase SQL Editor

-- Adaugă coloana assigned_to
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES users(id) ON DELETE SET NULL;

-- Adaugă index pentru performanță
CREATE INDEX IF NOT EXISTS idx_tasks_assigned ON tasks(assigned_to);

-- Verifică rezultatul
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'tasks'
ORDER BY ordinal_position;
