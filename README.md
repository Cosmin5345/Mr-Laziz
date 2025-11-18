# TaskFlow - Collaborative Task Manager

**Modern task management application with real-time collaboration**

## 📋 Overview

Full-stack mobile task management application built with Flutter and Supabase, featuring:

- **Backend**: Supabase (PostgreSQL + Real-time + Auth + Storage)
- **Frontend**: Flutter (Android, iOS, Web, Windows, macOS, Linux)
- **Features**: Multi-group collaboration, real-time notifications, analytics, priority system, calendar view

## 🌟 Key Features

### 🔐 Authentication & Security

- Secure registration with strong password validation (min 8 chars, uppercase, lowercase, digits, special chars)
- Visual password strength indicator
- JWT token-based authentication via Supabase
- Persistent login with auto-login on app restart
- Remember last opened project

### 👥 Group Management

- Create unlimited workspaces/groups
- Invite members with unique invite codes
- Role-based access (Owner/Member)
- Switch between multiple groups
- Leave/delete groups

### ✅ Task Management

- **CRUD Operations**: Create, read, update, delete tasks
- **3 Priority Levels**: High (red), Medium (orange), Low (green) with automatic sorting
- **Status Tracking**: Todo, In Progress, Done
- **Task Assignment**: Assign tasks to group members
- **Deadlines**: Set and track due dates
- **Details**: Rich descriptions and metadata

### 📊 Analytics Dashboard

- Task statistics (total, completed, in progress, overdue)
- Visual charts (pie chart, bar chart, timeline)
- Activity history feed
- Filter by date range

### � Schedule View

- Calendar integration with deadline markers
- Month/week views
- Task filtering by date
- Quick task creation for selected dates

### 🔔 Notification System

- Real-time push notifications
- Owner notified when member changes task status
- Member notified when assigned to task
- Focus Mode (Do Not Disturb)
- Mark as read/unread
- Swipe to delete

### 🎨 Modern UI/UX

- Material Design 3
- Dark-aware color scheme
- Gradient buttons and cards
- Smooth animations
- Pull-to-refresh
- Responsive layout

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.9.2+
- Supabase account (free tier works)

### 1. Setup Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the setup script:
   - Create tables: `users`, `groups`, `tasks`, `group_members`, `notifications`
   - Enable Row Level Security (RLS)
   - Create database functions for group/task management
3. Note your project URL and anon key from **Settings > API**

### 2. Configure App

Create `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  static const String usersTable = 'users';
  static const String tasksTable = 'tasks';
  static const String groupsTable = 'groups';
  static const String groupMembersTable = 'group_members';
  static const String notificationsTable = 'notifications';
}
```

### 3. Install & Run

```bash
cd task_manager
flutter pub get
flutter run
```

**For physical devices**: App automatically handles localhost connections via Supabase cloud.

## 📁 Project Structure

```
task_manager/
├── lib/
│   ├── main.dart                    # Entry point with auth check
│   ├── config/
│   │   └── supabase_config.dart    # Supabase credentials
│   ├── models/
│   │   ├── task.dart               # Task model with priority
│   │   ├── group.dart              # Group/workspace model
│   │   ├── user.dart               # User model
│   │   ├── notification.dart       # Notification model
│   │   └── task_history.dart      # Activity log model
│   ├── screens/
│   │   ├── auth_screen.dart        # Login/Register with validation
│   │   ├── home_screen.dart        # Main dashboard with task list
│   │   ├── create_task_screen.dart # Task creation form
│   │   ├── task_details_screen.dart # Task editor
│   │   ├── projects_screen.dart    # Group management
│   │   ├── schedule_screen.dart    # Calendar view
│   │   ├── analytics_screen.dart   # Charts and statistics
│   │   └── notifications_screen.dart # Notification center
│   ├── services/
│   │   ├── api_service.dart        # Task operations
│   │   ├── auth_service.dart       # Authentication
│   │   ├── group_service.dart      # Group management
│   │   ├── notification_service.dart # Notifications
│   │   ├── user_service.dart       # User profile
│   │   └── preferences_service.dart # Local storage
│   ├── ui/
│   │   ├── theme/                  # App theme and colors
│   │   └── widgets/                # Reusable components
│   └── utils/
│       └── password_validator.dart # Password security
└── pubspec.yaml
```

## 🛠️ Technology Stack

### Frontend

- **Flutter 3.9.2** - Cross-platform framework
- **Material 3** - Modern design system
- **Supabase Flutter** - Backend integration
- **table_calendar** - Calendar widget
- **fl_chart** - Data visualization
- **shared_preferences** - Local persistence
- **flutter_secure_storage** - Secure token storage

### Backend (Supabase)

- **PostgreSQL** - Database
- **PostgREST** - Auto-generated REST API
- **GoTrue** - Authentication
- **Realtime** - WebSocket subscriptions
- **Row Level Security** - Data access policies

## 🎯 Usage Guide

### Creating Your First Task

1. **Login/Register** - Create account with secure password
2. **Default Workspace** - Auto-created on first login
3. **Create Task** - Tap FAB button, fill form:
   - Title (required)
   - Description (optional)
   - Priority (High/Medium/Low)
   - Deadline (optional)
4. **View Tasks** - Sorted by priority, filterable, searchable

### Working with Groups

1. **Create Group** - Projects tab → New Group
2. **Invite Members** - Share 6-character invite code
3. **Join Group** - Use invite code
4. **Switch Groups** - Drawer menu → Select group

### Managing Tasks

- **Change Priority** - Tap ⋮ menu → Change Priority
- **Update Status** - Swipe or use status dropdown
- **Assign Task** - Task details → Assign to member
- **Set Deadline** - Calendar picker in task form
- **Delete Task** - Swipe left or ⋮ menu

### Viewing Analytics

- **Statistics** - Total, completed, in progress, overdue
- **Charts** - Visual breakdown by priority and timeline
- **History** - Recent activity log

## 📱 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Windows (10+)
- ✅ macOS (10.14+)
- ✅ Linux

## 🔒 Security Features

- ✅ BCrypt-style password hashing via Supabase
- ✅ JWT token authentication
- ✅ Row Level Security (users see only their groups/tasks)
- ✅ Secure token storage (flutter_secure_storage)
- ✅ Password strength validation
- ✅ Session persistence

## 📊 Database Schema

### Tables

- `users` - User profiles
- `groups` - Workspaces/projects
- `tasks` - Task items with priority, status, deadline
- `group_members` - User-group relationships with roles
- `notifications` - Real-time notification feed
- `task_history` - Audit trail

### Key Relations

- User → Groups (many-to-many via group_members)
- Group → Tasks (one-to-many)
- Task → User (assigned_to, foreign key)
- Notification → User (one-to-many)

## 🚧 Known Limitations

- Task assignment validation (3x limit) - not enforced yet
- End-to-End encryption - not implemented
- Subtasks/hierarchy - not implemented
- Task flow diagram - not visualized

## 🔮 Future Enhancements

- [ ] E2E encryption for sensitive data
- [ ] Subtask support
- [ ] File attachments
- [ ] Task templates
- [ ] Time tracking
- [ ] Recurring tasks
- [ ] Comments/discussions
- [ ] Task dependencies
- [ ] Custom fields
- [ ] Export to PDF/CSV

## 👥 Team

**Mr-Laziz** - 4 lei, 1 chelios si 3 spartani

## 📄 License

This project is part of an academic assignment.

---

**Built with ❤️ using Flutter & Supabase**
