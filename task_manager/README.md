# Task Manager - Flutter + Supabase

O aplicație modernă de task management construită cu Flutter și Supabase, cu funcționalități real-time și autentificare securizată.

## ✨ Funcționalități

- 🔐 **Autentificare**: Sign up, Sign in, Sign out cu Supabase Auth
- 📋 **CRUD Task-uri**: Creează, citește, actualizează și șterge task-uri
- 🎯 **Kanban Board**: Drag & drop între coloane (To Do, In Progress, Done)
- 👥 **Asignare**: Asignează task-uri la utilizatori
- ⚡ **Real-time**: Actualizări live pentru task-uri
- 🔒 **Row Level Security**: Securitate avansată la nivel de bază de date

## 🚀 Quick Start

### Opțiunea 1: Setup rapid (5 minute)

Urmărește ghidul din [`QUICK_START.md`](QUICK_START.md)

### Opțiunea 2: Setup detaliat

Citește [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md) pentru configurare completă

## 📋 Cerințe

- Flutter SDK: ^3.9.2
- Dart SDK: ^3.9.2
- Cont Supabase (gratuit)

## 🛠️ Instalare

1. **Clonează repository-ul**

```bash
git clone <repo-url>
cd task_manager
```

2. **Instalează dependențele**

```bash
flutter pub get
```

3. **Configurează Supabase**

   - Creează un proiect în [Supabase Dashboard](https://supabase.com/dashboard)
   - Rulează SQL-ul din `supabase_setup.sql` în SQL Editor
   - Copiază credențialele în `lib/config/supabase_config.dart`

4. **Rulează aplicația**

```bash
flutter run
```

## 📁 Structura Proiectului

```
lib/
├── config/
│   └── supabase_config.dart    # Configurare Supabase
├── models/
│   ├── task.dart               # Model Task
│   └── user.dart               # Model User
├── screens/
│   ├── auth_screen.dart        # Ecran autentificare
│   ├── task_board_screen.dart  # Ecran principal Kanban
│   ├── create_task_screen.dart # Ecran creare task
│   └── task_details_screen.dart # Detalii task
├── services/
│   ├── auth_service.dart       # Serviciu autentificare Supabase
│   └── api_service.dart        # Serviciu API Supabase
└── main.dart                   # Entry point
```

## 🗄️ Schema Bazei de Date

### Tabel `users`

```sql
- id (UUID, PK)
- username (TEXT, UNIQUE)
- email (TEXT, UNIQUE)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Tabel `tasks`

```sql
- id (SERIAL, PK)
- title (TEXT)
- description (TEXT)
- status (TEXT) - 'To Do', 'In Progress', 'Done'
- created_by (UUID, FK → auth.users)
- assigned_to (INTEGER, FK → users)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

## 🔧 Tehnologii Folosite

- **Flutter**: Framework UI
- **Supabase**: Backend-as-a-Service
  - PostgreSQL: Bază de date
  - Auth: Autentificare
  - Row Level Security: Securitate
  - Real-time: Subscripții live
- **flutter_secure_storage**: Stocare securizată token-uri

## 📱 Screenshots

_(Adaugă screenshots aici)_

## 🧪 Testare

1. **Înregistrează-te** cu un username și parolă
2. **Creează task-uri** noi
3. **Drag & drop** între coloane pentru a schimba statusul
4. **Asignează** task-uri la utilizatori
5. **Deschide în mai multe dispozitive** pentru a vedea real-time sync

## 🐛 Debugging

### Probleme comune

**Error: Connection failed**

- Verifică `supabaseUrl` și `supabaseAnonKey` în `supabase_config.dart`
- Verifică conexiunea la internet

**Error: Sign up failed**

- Activează Email Auth în Supabase Dashboard
- Verifică că RLS policies sunt configurate

**Task-urile nu se încarcă**

- Verifică că SQL setup s-a executat corect
- Verifică policies în Supabase Dashboard

## 📚 Resurse

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)

## 👨‍💻 Dezvoltare

Pentru a contribui sau modifica:

1. Fork repository-ul
2. Creează un branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Deschide un Pull Request

## 📄 Licență

Acest proiect este open source și disponibil sub [MIT License](LICENSE).

## 🙏 Mulțumiri

- Flutter team pentru framework-ul excelent
- Supabase team pentru BaaS gratuit și puternic
