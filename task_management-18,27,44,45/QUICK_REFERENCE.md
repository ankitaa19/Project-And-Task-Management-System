# 🚀 Quick Reference Card

## ⚡ Run Commands

### Backend
```bash
cd backend
node server.js
```
**URL**: http://localhost:3000

### Frontend
```bash
cd frontend
flutter run -d chrome
```

---

## 🔐 Default Credentials

```
Email:    admin@123
Password: admin123
```

---

## 📡 Key API Endpoints

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| POST | `/api/auth/login` | Login | ❌ |
| GET | `/api/users` | List users | ✅ Admin |
| POST | `/api/users` | Create user | ✅ Admin |
| GET | `/api/projects` | List projects | ✅ All |
| POST | `/api/projects` | Create project | ✅ Admin, Manager |
| GET | `/api/tasks` | List tasks | ✅ All |
| POST | `/api/tasks` | Create task | ✅ Admin, Manager |
| PATCH | `/api/tasks/:id/status` | Update status | ✅ All |
| GET | `/api/notifications` | Get notifications | ✅ All |

---

## 👥 User Roles

| Role | Can Do |
|------|--------|
| **Admin** 👑 | Everything + Create Users |
| **Manager** 🧑‍💼 | Projects + Tasks |
| **Member** 👨‍💻 | Update Own Tasks |

---

## 📱 Flutter Screens

| Role | Dashboard |
|------|-----------|
| Admin | AdminDashboard |
| Manager | ManagerDashboard |
| Member | MemberDashboard |

---

## 🗄️ Collections

- `users` - User accounts
- `projects` - Projects
- `tasks` - Tasks
- `activitylogs` - Audit trail
- `notifications` - In-app alerts

---

## 🔍 Quick Tests

### Test Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@123","password":"admin123"}'
```

### Check MongoDB
```bash
mongosh
use task_management_db
db.users.find().pretty()
```

---

## 📂 Key Files

### Backend
- `backend/server.js` - Main server
- `backend/.env` - Configuration
- `backend/models/` - Database models
- `backend/routes/` - API endpoints

### Frontend
- `frontend/lib/main.dart` - App entry
- `frontend/lib/config/api_config.dart` - API URL
- `frontend/lib/services/` - Business logic
- `frontend/lib/screens/` - UI screens

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Backend won't start | Check MongoDB running |
| Port 3000 in use | Change PORT in .env |
| Login fails | Verify admin user created |
| Flutter can't connect | Check baseUrl in api_config.dart |

---

## 🎯 Common Tasks

### Create a Manager
```bash
# Login first, get token
curl -X POST http://localhost:3000/api/users \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane",
    "email": "jane@example.com",
    "password": "pass123",
    "role": "manager"
  }'
```

### Create a Project
```bash
curl -X POST http://localhost:3000/api/projects \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Project",
    "managerId": "MANAGER_ID"
  }'
```

### Create a Task
```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Task Title",
    "projectId": "PROJECT_ID",
    "assignedTo": "USER_ID",
    "priority": "high"
  }'
```

---

## 📚 Documentation

1. **README.md** - Full overview
2. **SETUP.md** - Setup guide
3. **API_TESTING.md** - API reference
4. **PROJECT_SUMMARY.md** - Complete summary

---

## 🎓 Learn More

- Backend: [backend/README.md](backend/README.md)
- Frontend: [frontend/README.md](frontend/README.md)
- Node.js: [nodejs.org](https://nodejs.org)
- Flutter: [flutter.dev](https://flutter.dev)
- MongoDB: [mongodb.com](https://mongodb.com)

---

**Keep this card handy while developing! 📌**
