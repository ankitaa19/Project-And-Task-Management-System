# 🚀 Quick Setup Guide

Complete step-by-step guide to get the Task Management System running.

## ⏱️ Estimated Time: 10 minutes

---

## Prerequisites

Before starting, make sure you have:

✅ **Node.js** (v16+) - [Download](https://nodejs.org/)
✅ **MongoDB** - [Download](https://www.mongodb.com/try/download/community) or use [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
✅ **Flutter** (v3.10+) - [Install Guide](https://flutter.dev/docs/get-started/install)
✅ **Code Editor** - VS Code, Android Studio, or IntelliJ IDEA

---

## Part 1: Backend Setup (5 minutes)

### Step 1: Install MongoDB

**Option A: Local MongoDB**
```bash
# macOS (using Homebrew)
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# Windows
# Download and install from: https://www.mongodb.com/try/download/community

# Linux (Ubuntu)
sudo apt-get install mongodb
sudo systemctl start mongodb
```

**Option B: MongoDB Atlas (Cloud)**
1. Create free account at [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Create a cluster
3. Get connection string
4. Update `.env` with your connection string

### Step 2: Install Backend Dependencies

```bash
# Navigate to backend directory
cd backend

# Install all dependencies
npm install

# You should see packages being installed:
# - express
# - mongoose
# - bcryptjs
# - jsonwebtoken
# - cors
# - dotenv
```

### Step 3: Configure Environment

The `.env` file is already created. Verify settings:

```env
MONGODB_URI=mongodb://localhost:27017/task_management_db
JWT_SECRET=your_super_secret_jwt_key_change_in_production
PORT=3000
ADMIN_EMAIL=admin@123
ADMIN_PASSWORD=admin123
```

**If using MongoDB Atlas**, update `MONGODB_URI`:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/task_management_db
```

### Step 4: Start Backend Server

```bash
# Still in backend directory
node server.js
```

**You should see:**
```
✅ Connected to MongoDB successfully
✅ Admin user created successfully
🚀 Server is running on http://localhost:3000

👤 Admin Credentials:
   Email: admin@123
   Password: admin123
```

**✅ Backend is ready! Keep this terminal open.**

---

## Part 2: Frontend Setup (5 minutes)

### Step 5: Check Flutter Installation

```bash
flutter doctor
```

You should see:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Connected device
```

If you see issues, run:
```bash
flutter doctor --android-licenses  # For Android
```

### Step 6: Install Flutter Dependencies

Open a **NEW terminal** (keep backend running):

```bash
# Navigate to frontend directory
cd frontend

# Get all Flutter packages
flutter pub get
```

**You should see:**
```
Running "flutter pub get" in frontend...
Got dependencies!
```

### Step 7: Run Flutter App

**Option A: Run on Web (Easiest)**
```bash
flutter run -d chrome
```

**Option B: Run on Android Emulator**
```bash
# First, start Android emulator
# Then:
flutter run
```

**Option C: Run on iOS Simulator (macOS only)**
```bash
open -a Simulator  # Start iOS Simulator
flutter run -d ios
```

### Step 8: Login to App

The Flutter app will open automatically. You should see:

1. **Splash Screen** (1 second)
2. **Login Screen**

**Enter credentials:**
```
Email: admin@123
Password: admin123
```

Click **Login** button.

**✅ You should see the Admin Dashboard!**

---

## ✅ Verification Checklist

- [ ] Backend server running on `http://localhost:3000`
- [ ] MongoDB connected (check backend terminal)
- [ ] Admin user created (check backend terminal)
- [ ] Flutter app launched successfully
- [ ] Logged in with admin credentials
- [ ] Admin Dashboard displayed

---

## 🎯 What to Try Next

### 1. Create a User (Admin)
- In Admin Dashboard, click "Create User"
- Add a Manager or Member
- Try logging in as that user

### 2. Create a Project (Admin or Manager)
- Click "Manage Projects"
- Create a new project
- Assign a manager

### 3. Create a Task (Admin or Manager)
- Create a task within a project
- Assign it to a member
- Check notifications

### 4. Update Task Status (Member)
- Login as member
- View assigned task
- Update status to "In Progress"

---

## 🔧 Common Issues & Solutions

### Issue: "Cannot connect to MongoDB"

**Solution:**
```bash
# Check if MongoDB is running
# macOS
brew services list | grep mongodb

# Linux
sudo systemctl status mongodb

# Restart MongoDB
brew services restart mongodb-community  # macOS
sudo systemctl restart mongodb           # Linux
```

### Issue: "Port 3000 already in use"

**Solution:**
```bash
# Option 1: Kill process on port 3000
# macOS/Linux
lsof -ti:3000 | xargs kill -9

# Option 2: Change port in .env
PORT=3001
```

### Issue: "Flutter pub get fails"

**Solution:**
```bash
flutter clean
flutter pub get

# If still fails:
flutter doctor
flutter upgrade
```

### Issue: "Cannot connect Flutter to backend"

**Android Emulator:**
```dart
// Edit lib/config/api_config.dart
const String baseUrl = 'http://10.0.2.2:3000/api';
```

**Physical Device:**
```dart
// Find your computer's IP:
// macOS: System Preferences > Network
// Linux: ip addr show
// Windows: ipconfig

const String baseUrl = 'http://YOUR_IP_HERE:3000/api';
```

### Issue: "Login fails with 401"

**Check:**
1. Backend is running
2. Admin user was created (check backend logs)
3. Correct credentials: `admin@123` / `admin123`
4. Backend URL in Flutter is correct

**Try:**
```bash
# Test backend directly
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@123","password":"admin123"}'
```

---

## 📁 Project Structure Quick Reference

```
Task Management System/
├── backend/              # Node.js Backend
│   ├── server.js        # Start here
│   ├── package.json
│   └── .env             # Configuration
│
└── frontend/            # Flutter App
    ├── lib/main.dart    # Start here
    └── pubspec.yaml     # Dependencies
```

---

## 🎓 For Development

### Backend: Watch for Changes
```bash
# Install nodemon globally
npm install -g nodemon

# Run with auto-reload
cd backend
nodemon server.js
```

### Flutter: Hot Reload
```bash
# While app is running, press:
r  # Reload (keeps state)
R  # Restart (clears state)
```

### Test API with curl
```bash
# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@123","password":"admin123"}'

# Copy token from response, then:
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🚀 Production Deployment

**Backend:**
- Deploy to Heroku, AWS, or Digital Ocean
- Use MongoDB Atlas for database
- Set environment variables
- Enable HTTPS

**Frontend:**
- Build for web: `flutter build web`
- Build for Android: `flutter build apk`
- Build for iOS: `flutter build ios`

---

## 📞 Need Help?

1. Check the main [README.md](README.md)
2. Review [Backend README](backend/README.md)
3. Review [Frontend README](frontend/README.md)
4. Check MongoDB logs
5. Check backend terminal for errors
6. Check Flutter console for errors

---

## 🎉 Success!

If you can:
- ✅ Login with admin credentials
- ✅ See the admin dashboard
- ✅ Backend shows no errors

**You're all set! Start building! 🚀**

---

**Pro Tip:** Keep both backend and frontend terminals visible side-by-side to monitor logs while developing.
