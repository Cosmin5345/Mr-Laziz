-- ================================================
-- SETUP COMPLET SUPABASE - VERSIUNE FINALĂ
-- ================================================
-- Acest script creează totul de la zero: tabele, triggers, funcții, policies
-- ATENȚIE: Șterge toate datele existente!

-- ================================================
-- 1. ȘTERGE TOTUL (tabele, funcții, triggers)
-- ================================================

-- Șterge utilizatorii din auth.users (ștergerea în cascadă va șterge și din tabela users)
DO $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN SELECT id FROM auth.users LOOP
    DELETE FROM auth.users WHERE id = user_record.id;
  END LOOP;
END $$;

-- Șterge tabelele în ordine (cascade șterge automat constraints)
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Șterge funcțiile
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS generate_invite_code() CASCADE;
DROP FUNCTION IF EXISTS add_group_leader() CASCADE;

-- ================================================
-- 2. CREEAZĂ TABELELE
-- ================================================

-- Tabela USERS (sincronizată cu auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela GROUPS
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  invite_code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela GROUP_MEMBERS (relație many-to-many între users și groups)
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('leader', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Tabela TASKS
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL CHECK (status IN ('Todo', 'InProgress', 'Done')) DEFAULT 'Todo',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- 3. CREEAZĂ INDEXURI
-- ================================================

CREATE INDEX idx_group_members_user ON group_members(user_id);
CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_tasks_group ON tasks(group_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_groups_invite ON groups(invite_code);

-- ================================================
-- 4. FUNCȚII
-- ================================================

-- Funcție pentru actualizare automată a updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Funcție pentru creare automată user în tabela users când se înregistrează
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcție pentru generare cod invite unic
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Funcție pentru creare grup + adăugare lider (totul într-o singură tranzacție)
-- IMPORTANT: Folosește SECURITY DEFINER pentru a bypassa RLS
CREATE OR REPLACE FUNCTION create_group_with_leader(
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_invite_code TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  invite_code TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
DECLARE
  v_group_id UUID;
  v_user_id UUID;
  v_invite_code TEXT;
BEGIN
  -- Obține ID-ul utilizatorului curent
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;
  
  -- Folosește codul furnizat sau generează unul nou
  IF p_invite_code IS NOT NULL THEN
    v_invite_code := p_invite_code;
  ELSE
    v_invite_code := generate_invite_code();
  END IF;
  
  -- Creează grupul
  INSERT INTO public.groups (name, description, invite_code)
  VALUES (p_name, p_description, v_invite_code)
  RETURNING groups.id INTO v_group_id;
  
  -- Adaugă creatorul ca lider
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (v_group_id, v_user_id, 'leader');
  
  -- Returnează datele grupului creat
  RETURN QUERY
  SELECT g.id, g.name, g.description, g.invite_code, g.created_at, g.updated_at
  FROM public.groups g
  WHERE g.id = v_group_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcție pentru join la grup folosind invite code
-- IMPORTANT: Folosește SECURITY DEFINER pentru a bypassa RLS
CREATE OR REPLACE FUNCTION join_group_by_invite_code(
  p_invite_code TEXT
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  invite_code TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
DECLARE
  v_group_id UUID;
  v_user_id UUID;
  v_user_email TEXT;
  v_existing_member_count INTEGER;
BEGIN
  -- Obține ID-ul utilizatorului curent
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;
  
  -- Verifică dacă utilizatorul există în tabela users, dacă nu, îl creează
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE users.id = v_user_id) THEN
    -- Obține email-ul utilizatorului din auth.users
    SELECT email INTO v_user_email FROM auth.users WHERE auth.users.id = v_user_id;
    
    -- Inserează utilizatorul în tabela users
    INSERT INTO public.users (id, email, full_name)
    VALUES (v_user_id, v_user_email, v_user_email);
  END IF;
  
  -- Găsește grupul după invite code
  SELECT g.id INTO v_group_id
  FROM public.groups g
  WHERE g.invite_code = UPPER(p_invite_code);
  
  IF v_group_id IS NULL THEN
    RAISE EXCEPTION 'Invalid invite code';
  END IF;
  
  -- Verifică dacă utilizatorul este deja membru
  SELECT COUNT(*) INTO v_existing_member_count
  FROM public.group_members gm
  WHERE gm.group_id = v_group_id AND gm.user_id = v_user_id;
  
  IF v_existing_member_count > 0 THEN
    RAISE EXCEPTION 'You are already a member of this group';
  END IF;
  
  -- Adaugă utilizatorul ca membru
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (v_group_id, v_user_id, 'member');
  
  -- Returnează datele grupului
  RETURN QUERY
  SELECT g.id, g.name, g.description, g.invite_code, g.created_at, g.updated_at
  FROM public.groups g
  WHERE g.id = v_group_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcție pentru creare task într-un grup
-- IMPORTANT: Folosește SECURITY DEFINER pentru a bypassa RLS
CREATE OR REPLACE FUNCTION create_task(
  p_group_id UUID,
  p_title TEXT,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  group_id UUID,
  title TEXT,
  description TEXT,
  status TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
DECLARE
  v_user_id UUID;
  v_user_email TEXT;
  v_task_id UUID;
BEGIN
  -- Obține ID-ul utilizatorului curent
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;
  
  -- Verifică dacă utilizatorul există în tabela users, dacă nu, îl creează
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE users.id = v_user_id) THEN
    -- Obține email-ul utilizatorului din auth.users
    SELECT email INTO v_user_email FROM auth.users WHERE auth.users.id = v_user_id;
    
    -- Inserează utilizatorul în tabela users
    INSERT INTO public.users (id, email, full_name)
    VALUES (v_user_id, v_user_email, v_user_email);
  END IF;
  
  -- Verifică dacă utilizatorul este membru al grupului
  IF NOT EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = p_group_id AND gm.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'You are not a member of this group';
  END IF;
  
  -- Creează task-ul
  INSERT INTO public.tasks (group_id, title, description, status, created_by)
  VALUES (p_group_id, p_title, p_description, 'Todo', v_user_id)
  RETURNING tasks.id INTO v_task_id;
  
  -- Returnează datele task-ului creat
  RETURN QUERY
  SELECT t.id, t.group_id, t.title, t.description, t.status, t.created_by, t.created_at, t.updated_at
  FROM public.tasks t
  WHERE t.id = v_task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 5. TRIGGERS
-- ================================================

-- Trigger pentru actualizare automată a updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger pentru creare automată user
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ================================================
-- 6. ACTIVEAZĂ RLS (Row Level Security)
-- ================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- ================================================
-- 7. POLICIES pentru USERS
-- ================================================

-- Utilizatorii pot vedea doar propriul profil
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid()::uuid);

-- Utilizatorii pot actualiza doar propriul profil
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid()::uuid);

-- Permite INSERT pentru trigger (handle_new_user)
CREATE POLICY "Enable insert for authenticated users only"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ================================================
-- 8. POLICIES pentru GROUPS
-- ================================================

-- Policy combinat simplificat pentru SELECT (membrii pot vedea grupurile lor)
CREATE POLICY "Members can view their groups"
  ON groups FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- Liderii pot actualiza propriile grupuri
CREATE POLICY "Leaders can update their groups"
  ON groups FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM group_members 
      WHERE group_id = groups.id 
        AND user_id = auth.uid()
        AND role = 'leader'
    )
  );

-- Liderii pot șterge propriile grupuri
CREATE POLICY "Leaders can delete their groups"
  ON groups FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM group_members 
      WHERE group_id = groups.id 
        AND user_id = auth.uid()
        AND role = 'leader'
    )
  );

-- ================================================
-- 9. POLICIES pentru GROUP_MEMBERS
-- ================================================

-- Policy simplificat pentru SELECT (vezi propriile membership-uri)
CREATE POLICY "View own memberships"
  ON group_members FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Permite join la grupuri (prin invite code)
CREATE POLICY "Join groups"
  ON group_members FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Poți șterge DOAR propriul membership (leave grup)
CREATE POLICY "Leave own groups"
  ON group_members FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Liderii pot actualiza roluri
CREATE POLICY "Leaders can update member roles"
  ON group_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.user_id = auth.uid()
        AND gm.role = 'leader'
    )
  );

-- ================================================
-- 10. POLICIES pentru TASKS
-- ================================================

-- Membrii pot vedea task-urile din grupurile lor
CREATE POLICY "Members can view group tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    group_id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- Membrii pot crea task-uri în grupurile lor
CREATE POLICY "Members can create tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    group_id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- Membrii pot actualiza task-uri din grupurile lor
CREATE POLICY "Members can update tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    group_id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- Membrii pot șterge task-uri din grupurile lor
CREATE POLICY "Members can delete tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (
    group_id IN (
      SELECT group_id 
      FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- ================================================
-- 11. VERIFICARE FINALĂ
-- ================================================

-- Verifică că toate tabelele există
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'groups', 'group_members', 'tasks')
ORDER BY table_name;

-- Verifică RLS status
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'groups', 'group_members', 'tasks')
ORDER BY tablename;

-- Verifică policies pe GROUPS
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'groups'
ORDER BY policyname;

-- Verifică policies pe GROUP_MEMBERS
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'group_members'
ORDER BY policyname;

-- Verifică triggers
SELECT 
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgenabled as enabled,
    proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname IN ('on_auth_user_created', 'on_group_created', 'update_users_updated_at', 'update_groups_updated_at', 'update_tasks_updated_at')
ORDER BY tgname;

-- Verifică funcții
SELECT 
    proname as function_name,
    prosecdef as is_security_definer
FROM pg_proc 
WHERE proname IN ('handle_new_user', 'generate_invite_code', 'add_group_leader', 'update_updated_at_column')
ORDER BY proname;

-- ================================================
-- SETUP COMPLET! 
-- ================================================
-- Acum poți testa crearea unui grup din aplicație!
