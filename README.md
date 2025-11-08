# Task Board Application - Mr-Laziz

**4 lei, 1 chelios si 3 spartani**

## 📋 Descriere

Aplicație full-stack Kanban-style Task Board Manager inspirată de Notion, cu:
- **Backend**: .NET 8 Minimal API cu SQLite și JWT authentication
- **Frontend**: Flutter (Android & iOS)
- **Features**: Autentificare, CRUD tasks, Kanban board (Todo/In Progress/Done), Task assignment

## 🚀 Quick Start

### Backend (.NET 8)

```bash
cd backend
dotnet restore
dotnet run
```

Backend-ul va rula pe `http://localhost:5000`

### Frontend (Flutter)

```bash
cd task_manager
flutter pub get
flutter run
```

**Important**: Dacă folosești un dispozitiv fizic, actualizează URL-ul în:
- `lib/services/auth_service.dart`
- `lib/services/api_service.dart`

Schimbă `http://10.0.2.2:5000` cu IP-ul calculatorului tău (ex: `http://192.168.1.100:5000`)

## 📁 Structura Proiectului

```
backend/
├── Program.cs                 # Main entry point cu toate endpoint-urile
├── TaskBoardApi.csproj        # Dependencies
├── Models/
│   ├── User.cs               # User entity
│   ├── TaskItem.cs           # Task entity
│   └── DTOs.cs               # Request/Response models
├── Data/
│   └── AppDbContext.cs       # EF Core DbContext
└── Services/
    ├── JwtService.cs         # JWT token generation
    └── PasswordService.cs    # BCrypt password hashing

task_manager/
├── lib/
│   ├── main.dart             # App entry point
│   ├── models/
│   │   ├── task.dart         # Task model
│   │   └── user.dart         # User model
│   ├── services/
│   │   ├── auth_service.dart # Authentication service
│   │   └── api_service.dart  # API calls service
│   └── screens/
│       ├── auth_screen.dart          # Login/Register
│       ├── task_board_screen.dart    # Main Kanban board
│       ├── create_task_screen.dart   # Create new task
│       └── task_details_screen.dart  # Edit task details
└── pubspec.yaml              # Flutter dependencies
```

## 🔐 API Endpoints

### Authentication (No Auth Required)
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and get JWT token

### Users (Auth Required)
- `GET /users` - Get all users (for assignment dropdown)

### Tasks (Auth Required)
- `GET /tasks` - Get all tasks
- `POST /tasks` - Create new task
- `PUT /tasks/{id}/status` - Update task status (Todo/InProgress/Done)
- `PUT /tasks/{id}/assign` - Assign task to user
- `PUT /tasks/{id}` - Update task details (title, description)

## 🛠️ Technology Stack

- **.NET 8** - Backend API framework
- **Entity Framework Core** - ORM
- **SQLite** - Lightweight database
- **BCrypt.Net** - Password hashing
- **JWT** - Token-based authentication
- **Flutter** - Cross-platform mobile framework
- **flutter_secure_storage** - Secure token storage
- **http** - HTTP client for API calls

## ✨ Features

- ✅ User registration and authentication
- ✅ JWT token-based security
- ✅ BCrypt password hashing
- ✅ Kanban board with 3 columns (To Do, In Progress, Done)
- ✅ Create, read, update tasks
- ✅ Assign tasks to users
- ✅ Move tasks between columns
- ✅ Pull-to-refresh
- ✅ Responsive UI

## 📱 Screenshots

### Login Screen
User authentication with register/login toggle

### Task Board
Three-tab Kanban board showing tasks by status

### Task Details
Edit task, change status, assign to users

### Create Task
Simple form to create new tasks

## 🔧 Development Notes

- Backend folosește **CORS** permisiv pentru development (AllowAnyOrigin)
- Database-ul SQLite (`tasks.db`) se creează automat la primul run
- JWT token expiră după 7 zile
- Flutter folosește `flutter_secure_storage` pentru token persistence

## 👥 Team

**Mr-Laziz** - 4 lei, 1 chelios si 3 spartani



