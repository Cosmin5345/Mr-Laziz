# Configurare Supabase pentru Task Manager

## Pași de configurare

### 1. Creează un cont Supabase

1. Mergi la [https://supabase.com](https://supabase.com)
2. Creează un cont gratuit
3. Creează un nou proiect

### 2. Obține credențialele

1. Du-te la **Project Settings** → **API**
2. Copiază:
   - **Project URL** (ex: `https://xxx.supabase.co`)
   - **anon/public key**

### 3. Configurează aplicația

1. Deschide fișierul `lib/config/supabase_config.dart`
2. Înlocuiește valorile:

```dart
static const String supabaseUrl = 'https://xxx.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

### 4. Creează tabelele în Supabase

#### Tabel `users`

Du-te la **SQL Editor** în Supabase și rulează:

```sql
-- Tabel pentru utilizatori
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pentru căutare rapidă
CREATE INDEX idx_users_username ON users(username);
```

#### Tabel `tasks`

```sql
-- Tabel pentru task-uri
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'To Do',
  created_by UUID REFERENCES auth.users(id),
  assigned_to INTEGER REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pentru performanță
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);

-- Trigger pentru updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tasks_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

### 5. Configurează Row Level Security (RLS)

#### Pentru tabelul `users`:

```sql
-- Activează RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Utilizatorii pot citi toți ceilalți utilizatori
CREATE POLICY "Users can view all users"
ON users FOR SELECT
TO authenticated
USING (true);

-- Utilizatorii pot adăuga propriul profil
CREATE POLICY "Users can insert their own profile"
ON users FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = id::text);
```

#### Pentru tabelul `tasks`:

```sql
-- Activează RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Utilizatorii pot vedea toate task-urile
CREATE POLICY "Users can view all tasks"
ON tasks FOR SELECT
TO authenticated
USING (true);

-- Utilizatorii pot crea task-uri
CREATE POLICY "Users can create tasks"
ON tasks FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = created_by);

-- Utilizatorii pot actualiza toate task-urile
CREATE POLICY "Users can update tasks"
ON tasks FOR UPDATE
TO authenticated
USING (true);

-- Utilizatorii pot șterge task-urile create de ei
CREATE POLICY "Users can delete their own tasks"
ON tasks FOR DELETE
TO authenticated
USING (auth.uid() = created_by);
```

### 6. Configurează Authentication

1. Du-te la **Authentication** → **Settings**
2. Sub **Auth Providers**, asigură-te că **Email** este activat
3. (Opțional) Dezactivează **Email Confirmations** pentru testare rapidă

### 7. Instalează dependențele și rulează aplicația

```powershell
# Instalează dependențele
flutter pub get

# Rulează aplicația
flutter run
```

## Funcționalități Supabase integrate

✅ **Autentificare**: Sign up, Sign in, Sign out  
✅ **CRUD Task-uri**: Create, Read, Update, Delete  
✅ **Asignare task-uri**: La utilizatori  
✅ **Real-time**: Actualizări live pentru task-uri  
✅ **Row Level Security**: Securitate la nivel de rând

## Testare

1. Înregistrează-te cu un username și parolă
2. Creează câteva task-uri
3. Schimbă statusul task-urilor (drag & drop)
4. Asignează task-uri la utilizatori

## Depanare

### Eroare de conexiune

- Verifică că `supabaseUrl` și `supabaseAnonKey` sunt corecte
- Verifică conexiunea la internet

### Erori de autentificare

- Asigură-te că Email Auth este activat în Supabase
- Verifică că RLS policies sunt configurate corect

### Task-urile nu se încarcă

- Verifică că tabelul `tasks` există
- Verifică că RLS policies permit citirea task-urilor

## Resurse utile

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Supabase SQL Editor](https://supabase.com/docs/guides/database/overview)
