/**
 * Main Server File
 * This file initializes the Express server, connects to MongoDB,
 * and sets up all routes and middleware
 */

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const projectRoutes = require('./routes/projectRoutes');
const taskRoutes = require('./routes/taskRoutes');
const activityLogRoutes = require('./routes/activityLogRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

// Import seed function for admin user
const { seedAdminUser } = require('./utils/seedAdmin');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware Setup
// Parse JSON bodies (for POST/PUT requests)
app.use(express.json());

// Enable CORS for Flutter app (allows frontend to make requests)
app.use(cors());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => {
    console.log('✅ Connected to MongoDB successfully');

    // Seed admin user if it doesn't exist
    seedAdminUser();
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1); // Exit if database connection fails
  });

// API Routes
// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Task Management System API',
    status: 'Running',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      projects: '/api/projects',
      tasks: '/api/tasks',
      activityLogs: '/api/activity-logs',
      notifications: '/api/notifications'
    }
  });
});

// Mount route handlers
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/activity-logs', activityLogRoutes);
app.use('/api/notifications', notificationRoutes);

// 404 Handler - catches undefined routes
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});

// Start Server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`\n👤 Admin Credentials:`);
  console.log(`   Email: ${process.env.ADMIN_EMAIL}`);
  console.log(`   Password: ${process.env.ADMIN_PASSWORD}\n`);
});

module.exports = app;
