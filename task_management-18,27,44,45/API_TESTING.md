# API Testing Guide

Quick reference for testing API endpoints using curl or any HTTP client.

## 🔐 Authentication

### Login
Get JWT token for authenticated requests.

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@123",
    "password": "admin123"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "name": "System Administrator",
    "email": "admin@123",
    "role": "admin"
  }
}
```

**Copy the token** for use in other requests!

---

## 👤 User Management (Admin Only)

### Get All Users
```bash
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Create User
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Manager",
    "email": "john@example.com",
    "password": "password123",
    "role": "manager"
  }'
```

### Toggle User Status (Activate/Deactivate)
```bash
curl -X PATCH http://localhost:3000/api/users/USER_ID_HERE/toggle-status \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📁 Project Management

### Get All Projects
```bash
curl http://localhost:3000/api/projects \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Create Project
```bash
curl -X POST http://localhost:3000/api/projects \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mobile App Development",
    "description": "Build a new mobile application",
    "managerId": "MANAGER_USER_ID_HERE"
  }'
```

### Update Project
```bash
curl -X PUT http://localhost:3000/api/projects/PROJECT_ID_HERE \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Project Name",
    "status": "active"
  }'
```

### Add Member to Project
```bash
curl -X POST http://localhost:3000/api/projects/PROJECT_ID_HERE/add-member \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "MEMBER_USER_ID_HERE"
  }'
```

### Remove Member from Project
```bash
curl -X DELETE http://localhost:3000/api/projects/PROJECT_ID_HERE/remove-member/USER_ID_HERE \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## ✅ Task Management

### Get All Tasks
```bash
curl http://localhost:3000/api/tasks \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Create Task
```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Design Database Schema",
    "description": "Create ER diagram and define tables",
    "projectId": "PROJECT_ID_HERE",
    "assignedTo": "USER_ID_HERE",
    "priority": "high",
    "deadline": "2024-12-31"
  }'
```

### Update Task Status
```bash
curl -X PATCH http://localhost:3000/api/tasks/TASK_ID_HERE/status \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in-progress"
  }'
```

**Valid statuses:** `pending`, `in-progress`, `completed`, `blocked`

### Assign Task
```bash
curl -X PATCH http://localhost:3000/api/tasks/TASK_ID_HERE/assign \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "USER_ID_HERE"
  }'
```

---

## 📊 Activity Logs

### Get All Logs (Admin)
```bash
curl http://localhost:3000/api/activity-logs \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Get Logs for Specific Project
```bash
curl "http://localhost:3000/api/activity-logs?projectId=PROJECT_ID_HERE" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Get Logs with Limit
```bash
curl "http://localhost:3000/api/activity-logs?limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🔔 Notifications

### Get All Notifications
```bash
curl http://localhost:3000/api/notifications \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Get Only Unread Notifications
```bash
curl "http://localhost:3000/api/notifications?unreadOnly=true" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Mark Notification as Read
```bash
curl -X PATCH http://localhost:3000/api/notifications/NOTIFICATION_ID_HERE/read \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Mark All Notifications as Read
```bash
curl -X PATCH http://localhost:3000/api/notifications/mark-all-read \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🧪 Complete Test Scenario

### Step 1: Login as Admin
```bash
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@123","password":"admin123"}' \
  | jq -r '.token')

echo "Token: $TOKEN"
```

### Step 2: Create a Manager
```bash
MANAGER=$(curl -X POST http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Manager",
    "email": "jane@example.com",
    "password": "pass123",
    "role": "manager"
  }' | jq -r '.user.id')

echo "Manager ID: $MANAGER"
```

### Step 3: Create a Member
```bash
MEMBER=$(curl -X POST http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bob Member",
    "email": "bob@example.com",
    "password": "pass123",
    "role": "member"
  }' | jq -r '.user.id')

echo "Member ID: $MEMBER"
```

### Step 4: Create a Project
```bash
PROJECT=$(curl -X POST http://localhost:3000/api/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Website Redesign\",
    \"description\": \"Redesign company website\",
    \"managerId\": \"$MANAGER\"
  }" | jq -r '.project._id')

echo "Project ID: $PROJECT"
```

### Step 5: Add Member to Project
```bash
curl -X POST http://localhost:3000/api/projects/$PROJECT/add-member \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$MEMBER\"}"
```

### Step 6: Create a Task
```bash
TASK=$(curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Design Homepage\",
    \"description\": \"Create mockups for new homepage\",
    \"projectId\": \"$PROJECT\",
    \"assignedTo\": \"$MEMBER\",
    \"priority\": \"high\",
    \"deadline\": \"2024-12-31\"
  }" | jq -r '.task._id')

echo "Task ID: $TASK"
```

### Step 7: Check Notifications
```bash
curl http://localhost:3000/api/notifications \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Verification Queries

### Check Database (MongoDB Shell)
```bash
mongosh
use task_management_db

# Count documents
db.users.countDocuments()
db.projects.countDocuments()
db.tasks.countDocuments()
db.activitylogs.countDocuments()
db.notifications.countDocuments()

# View admin user
db.users.findOne({email: "admin@123"})

# View all projects
db.projects.find().pretty()

# View recent activity
db.activitylogs.find().sort({timestamp: -1}).limit(10).pretty()
```

---

## 🎯 Postman Collection

If you prefer Postman:

1. **Create a new collection** named "Task Management API"
2. **Add environment variables:**
   - `BASE_URL`: http://localhost:3000/api
   - `TOKEN`: (will be set after login)

3. **Import these endpoints:**
   - Auth > Login
   - Users > Get All Users
   - Users > Create User
   - Projects > Create Project
   - Tasks > Create Task
   - Tasks > Update Status

4. **After login:**
   - Copy token from response
   - Set it in environment variable
   - Use `{{TOKEN}}` in Authorization header

---

## 📝 Response Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (invalid data)
- `401` - Unauthorized (no/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Server Error

---

## 🐛 Debugging Tips

### Enable Verbose Output
```bash
curl -v http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN"
```

### Format JSON Output
```bash
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'
```

### Save Response to File
```bash
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN" \
  -o users.json
```

---

**Happy Testing! 🚀**
