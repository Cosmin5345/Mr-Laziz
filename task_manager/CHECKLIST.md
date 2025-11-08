# ✅ Checklist Configurare Supabase

Urmărește acești pași pentru a integra Supabase în aplicația ta.

## Partea 1: Setup Supabase (în browser)

- [ ] **1.1** Mergi la https://supabase.com și creează cont
- [ ] **1.2** Click pe "New Project"
- [ ] **1.3** Completează:
  - [ ] Name: `task-manager-app` (sau alt nume)
  - [ ] Database Password: (generează automat sau creează unul)
  - [ ] Region: (alege cel mai apropiat)
  - [ ] Click "Create new project" (durează ~2 minute)

## Partea 2: Obține Credențiale

- [ ] **2.1** În dashboard, click pe Settings (⚙️) din sidebar
- [ ] **2.2** Click pe "API"
- [ ] **2.3** Copiază:
  - [ ] **Project URL** (exemplu: `https://xxx.supabase.co`)
  - [ ] **anon/public key** (lung string)

## Partea 3: Configurare Aplicație Flutter

- [ ] **3.1** Deschide `lib/config/supabase_config.dart`
- [ ] **3.2** Înlocuiește `YOUR_SUPABASE_URL` cu URL-ul tău
- [ ] **3.3** Înlocuiește `YOUR_SUPABASE_ANON_KEY` cu key-ul tău
- [ ] **3.4** Salvează fișierul

## Partea 4: Setup Baza de Date

- [ ] **4.1** În Supabase Dashboard, click pe "SQL Editor" din sidebar
- [ ] **4.2** Click pe "New Query"
- [ ] **4.3** Deschide fișierul `supabase_setup.sql` din proiect
- [ ] **4.4** Copiază **TOT** conținutul SQL
- [ ] **4.5** Paste în SQL Editor din Supabase
- [ ] **4.6** Click pe "Run" (sau Ctrl+Enter)
- [ ] **4.7** Verifică că nu sunt erori (ar trebui să fie "Success")

## Partea 5: Verificare Tabele

- [ ] **5.1** Click pe "Table Editor" din sidebar
- [ ] **5.2** Verifică că vezi tabelele:
  - [ ] `users`
  - [ ] `tasks`

## Partea 6: Configurare Authentication

- [ ] **6.1** Click pe "Authentication" din sidebar
- [ ] **6.2** Click pe "Settings"
- [ ] **6.3** Sub "Auth Providers", verifică că **Email** este activat (toggle verde)
- [ ] **6.4** (Opțional pentru testare) Sub "Email Auth":
  - [ ] Dezactivează "Confirm email" (ca să poți testa rapid)
  - [ ] Dezactivează "Secure email change" (opțional)

## Partea 7: Verificare Policies (Securitate)

- [ ] **7.1** Click pe "Database" → "Policies" din sidebar
- [ ] **7.2** Verifică că vezi policies pentru:
  - [ ] Tabelul `users` (3 policies)
  - [ ] Tabelul `tasks` (4 policies)

## Partea 8: Rulare Aplicație

- [ ] **8.1** Deschide terminal în folder-ul `task_manager`
- [ ] **8.2** Rulează: `flutter pub get`
- [ ] **8.3** Așteaptă ca toate pachetele să se instaleze
- [ ] **8.4** Rulează: `flutter run`
- [ ] **8.5** Alege dispozitivul (Android/iOS/Web/Desktop)

## Partea 9: Test Aplicație

- [ ] **9.1** Click pe "Sign Up"
- [ ] **9.2** Introdu:
  - [ ] Username: (orice username)
  - [ ] Password: (minim 6 caractere)
- [ ] **9.3** Verifică că ești autentificat (vezi ecranul principal)
- [ ] **9.4** Click pe "+" pentru a crea un task
- [ ] **9.5** Completează Title și Description
- [ ] **9.6** Click "Create"
- [ ] **9.7** Verifică că task-ul apare în coloana "To Do"

## Partea 10: Verificare în Supabase Dashboard

- [ ] **10.1** În browser, mergi la Supabase Dashboard
- [ ] **10.2** Click pe "Table Editor" → `tasks`
- [ ] **10.3** Verifică că vezi task-ul creat
- [ ] **10.4** Click pe "Authentication" → "Users"
- [ ] **10.5** Verifică că vezi utilizatorul creat

## 🎉 Succes!

Dacă toate checkboxurile sunt bifate, ai integrat cu succes Supabase!

---

## 🆘 Probleme?

### Nu văd tabelele în Table Editor

→ Verifică că SQL-ul s-a executat fără erori. Rulează din nou `supabase_setup.sql`

### Sign up nu funcționează

→ Verifică că Email Auth este activat în Authentication → Settings

### Connection error în app

→ Verifică că ai copiat corect URL-ul și anon key în `supabase_config.dart`

### Task-urile nu se încarcă

→ Verifică policies în Database → Policies. Ar trebui să vezi policies pentru `tasks`

---

## 📝 Note

- Anon key este **sigur** să fie în cod - este destinat să fie public
- Pentru production, consideră environment variables
- Nu împărtăși niciodată **service_role key** (e secret!)
