/**
 * User Model
 * Represents users in the system (admin, manager, member)
 */

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // User's full name
  name: {
    type: String,
    required: true,
    trim: true
  },

  // Email address (used for login)
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },

  // Hashed password (never store plain text!)
  password: {
    type: String,
    required: true
  },

  // User role: determines permissions
  // admin - Full access
  // manager - Can manage projects and tasks
  // member - Can only update their own tasks
  role: {
    type: String,
    enum: ['admin', 'manager', 'member'],
    default: 'member'
  },

  // Account status (admins can deactivate users)
  isActive: {
    type: Boolean,
    default: true
  },

  // Timestamps for record keeping
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  // Automatically add createdAt and updatedAt timestamps
  timestamps: true
});

// Create index on email for faster lookups
userSchema.index({ email: 1 });

module.exports = mongoose.model('User', userSchema);
