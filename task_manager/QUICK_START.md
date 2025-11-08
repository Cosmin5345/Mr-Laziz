# 🚀 Start Rapid cu Supabase

## Configurare rapidă (5 minute)

### 1️⃣ Configurează Supabase (2 min)

```
1. Mergi la: https://supabase.com/dashboard
2. Creează cont + New Project
3. Alege:
   - Name: task-manager-app
   - Database Password: (generează automat)
   - Region: (cel mai apropiat de tine)
   - Plan: Free
```

### 2️⃣ Copiază credențialele (1 min)

```
1. Click pe proiect → Settings (⚙️) → API
2. Copiază:
   - Project URL
   - anon public key
```

### 3️⃣ Actualizează config (30 sec)

Deschide: `lib/config/supabase_config.dart`

```dart
static const String supabaseUrl = 'PASTE_URL_HERE';
static const String supabaseAnonKey = 'PASTE_KEY_HERE';
```

### 4️⃣ Creează tabelele (1.5 min)

În Supabase Dashboard → SQL Editor → New Query:

**Copiază și rulează acest SQL:**

```sql
-- Tabel users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabel tasks
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

-- Indexuri pentru performanță
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);

-- RLS pentru securitate
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all users" ON users FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can insert their own profile" ON users FOR INSERT TO authenticated WITH CHECK (auth.uid()::text = id::text);

CREATE POLICY "Users can view all tasks" ON tasks FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can create tasks" ON tasks FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update tasks" ON tasks FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Users can delete their own tasks" ON tasks FOR DELETE TO authenticated USING (auth.uid() = created_by);
```

### 5️⃣ Configurează Auth (30 sec)

```
1. Authentication → Settings
2. Email Auth → Activat ✓
3. (Opțional) Disable "Confirm email" pentru testare rapidă
```

### 6️⃣ Rulează app-ul! 🎉

```powershell
flutter run
```

---

## ✅ Verificare rapidă

După ce rulezi app-ul:

1. **Register**: Creează cont cu username + parolă
2. **Create Task**: Adaugă un task nou
3. **Drag & Drop**: Mută task-ul între coloane
4. **Check Supabase**: Vezi task-ul în Table Editor

---

## 🆘 Probleme comune

### "Connection failed"

→ Verifică `supabaseUrl` și `supabaseAnonKey` în `supabase_config.dart`

### "Sign up failed"

→ Authentication → Settings → Activează Email Auth

### "Can't read tasks"

→ Verifică că SQL-ul s-a executat corect (vezi toate tabelele în Table Editor)

---

## 📚 Next Steps

Citește `SUPABASE_SETUP.md` pentru:

- Configurare detaliată RLS
- Real-time subscriptions
- Security best practices
- Advanced features

**Gata! Ai Supabase integrat! 🚀**
