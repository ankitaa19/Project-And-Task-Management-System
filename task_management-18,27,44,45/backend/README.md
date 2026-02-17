# Backend - Task Management System

Node.js + Express + MongoDB backend with JWT authentication and RBAC.

## 📦 Technologies

- **Node.js** - JavaScript runtime
- **Express** - Web framework
- **MongoDB** - NoSQL database
- **Mongoose** - MongoDB ODM
- **JWT** - Authentication tokens
- **bcryptjs** - Password hashing
- **CORS** - Cross-origin requests

## 🏗️ Architecture

```
backend/
├── models/              # Database models
│   ├── User.js         # User model (admin/manager/member)
│   ├── Project.js      # Project model
│   ├── Task.js         # Task model
│   ├── ActivityLog.js  # Audit log model
│   └── Notification.js # Notification model
│
├── routes/             # API routes
│   ├── authRoutes.js        # Login endpoint
│   ├── userRoutes.js        # User management (Admin)
│   ├── projectRoutes.js     # Project CRUD
│   ├── taskRoutes.js        # Task CRUD
│   ├── activityLogRoutes.js # Activity logs
│   └── notificationRoutes.js# Notifications
│
├── middleware/         # Custom middleware
│   ├── authMiddleware.js    # JWT verification
│   └── rbacMiddleware.js    # Role-based access control
│
├── utils/              # Utility functions
│   └── seedAdmin.js         # Creates admin user
│
├── server.js           # Main server file
├── package.json        # Dependencies
└── .env               # Environment variables
```

## 🔐 Security Features

### JWT Authentication
- Token expires in 7 days
- Token includes userId and role
- Verified on every protected route

### Password Security
- Passwords hashed with bcrypt (10 rounds)
- Never stored in plain text
- Never returned in API responses

### RBAC (Role-Based Access Control)
```javascript
// Three roles with different permissions:

Admin:
- Full access to all endpoints
- Can create users
- Can view all logs

Manager:
- Can manage their own projects
- Can create and assign tasks
- Can view project logs

Member:
- Can view assigned tasks
- Can update task status
- Can view own activity logs
```

## 🚀 Running the Backend

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Edit `.env` file:
```env
MONGODB_URI=mongodb://localhost:27017/task_management_db
JWT_SECRET=change_this_secret_in_production
PORT=3000
ADMIN_EMAIL=admin@123
ADMIN_PASSWORD=admin123
```

### 3. Start MongoDB
```bash
# If using local MongoDB
mongod

# Or use MongoDB Atlas (cloud)
# Update MONGODB_URI in .env
```

### 4. Start Server
```bash
node server.js
```

You should see:
```
✅ Connected to MongoDB successfully
✅ Admin user created successfully
🚀 Server is running on http://localhost:3000
```

## 📡 API Documentation

### Authentication

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@123",
  "password": "admin123"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_id",
    "name": "System Administrator",
    "email": "admin@123",
    "role": "admin"
  }
}
```

### Users (Admin Only)

#### Get All Users
```http
GET /api/users
Authorization: Bearer <token>

Response:
{
  "count": 5,
  "users": [...]
}
```

#### Create User
```http
POST /api/users
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "member"  // admin, manager, or member
}
```

### Projects

#### Create Project
```http
POST /api/projects
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "New Project",
  "description": "Project description",
  "managerId": "manager_user_id"
}
```

### Tasks

#### Create Task
```http
POST /api/tasks
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Task Title",
  "description": "Task description",
  "projectId": "project_id",
  "assignedTo": "user_id",
  "priority": "high",
  "deadline": "2024-12-31"
}
```

#### Update Task Status
```http
PATCH /api/tasks/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "in-progress"  // pending, in-progress, completed, blocked
}
```

## 🗄️ Database Schema

### User Collection
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  role: String (admin/manager/member),
  isActive: Boolean,
  createdAt: Date
}
```

### Project Collection
```javascript
{
  name: String,
  description: String,
  manager: ObjectId (ref: User),
  members: [ObjectId] (ref: User),
  status: String (active/completed/on-hold),
  createdBy: ObjectId (ref: User),
  createdAt: Date
}
```

### Task Collection
```javascript
{
  title: String,
  description: String,
  project: ObjectId (ref: Project),
  assignedTo: ObjectId (ref: User),
  status: String (pending/in-progress/completed/blocked),
  priority: String (low/medium/high/urgent),
  deadline: Date,
  createdBy: ObjectId (ref: User),
  createdAt: Date
}
```

### ActivityLog Collection
```javascript
{
  action: String (USER_CREATED, TASK_ASSIGNED, etc.),
  performedBy: ObjectId (ref: User),
  project: ObjectId (ref: Project),
  task: ObjectId (ref: Task),
  affectedUser: ObjectId (ref: User),
  details: String,
  timestamp: Date
}
```

### Notification Collection
```javascript
{
  userId: ObjectId (ref: User),
  message: String,
  type: String (task_assigned/deadline_near/etc.),
  task: ObjectId (ref: Task),
  project: ObjectId (ref: Project),
  isRead: Boolean,
  createdAt: Date
}
```

## 🔍 Activity Logging

Every important action is automatically logged:
- User creation/update
- Project creation/update
- Member addition/removal
- Task creation/assignment
- Task status changes
- Login attempts

Example:
```javascript
await ActivityLog.create({
  action: 'TASK_ASSIGNED',
  performedBy: req.user._id,
  project: task.project,
  task: task._id,
  affectedUser: userId,
  details: `Assigned task: ${task.title}`
});
```

## 🔔 Notification System

Notifications are created automatically when:
- User is assigned to a task
- User is added to a project
- Task status changes
- Deadline approaches

Flutter app polls `/api/notifications` every 15 seconds to check for new notifications.

## 🛠️ Development Tips

### Testing APIs
Use Postman or Thunder Client:

1. Login to get token
2. Copy token
3. Add to Authorization header: `Bearer <token>`
4. Test other endpoints

### Checking MongoDB
```bash
# Connect to MongoDB shell
mongosh

# Switch to database
use task_management_db

# View collections
show collections

# Query users
db.users.find().pretty()
```

### Common Issues

**Port already in use:**
```bash
# Change PORT in .env
PORT=3001
```

**MongoDB connection error:**
```bash
# Make sure MongoDB is running
mongod
```

**Admin user not created:**
```bash
# Delete existing user and restart
db.users.deleteOne({email: "admin@123"})
```

## 📈 Performance Optimization

- Indexes on frequently queried fields (email, project members, task assignedTo)
- Populate only necessary fields
- Limit query results
- Connection pooling with Mongoose

## 🔒 Production Checklist

- [ ] Change JWT_SECRET to a strong random string
- [ ] Use MongoDB Atlas or production database
- [ ] Enable HTTPS
- [ ] Add rate limiting
- [ ] Implement request validation
- [ ] Add logging (Winston/Morgan)
- [ ] Set up error monitoring
- [ ] Use environment-specific configs
- [ ] Add API documentation (Swagger)
- [ ] Implement refresh tokens

## 📚 Learn More

- [Express Documentation](https://expressjs.com/)
- [Mongoose Documentation](https://mongoosejs.com/)
- [JWT.io](https://jwt.io/)
- [MongoDB Manual](https://docs.mongodb.com/)

---

**Need help? Check the main README or open an issue!**
