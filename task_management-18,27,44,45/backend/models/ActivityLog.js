/**
 * Activity Log Model
 * Tracks all actions performed in the system for audit purposes
 */

const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
  // Type of action performed
  action: {
    type: String,
    required: true,
    enum: [
      'USER_CREATED',
      'USER_UPDATED',
      'USER_DEACTIVATED',
      'USER_DELETED',
      'PROJECT_CREATED',
      'PROJECT_UPDATED',
      'MEMBER_ADDED',
      'MEMBER_REMOVED',
      'TASK_CREATED',
      'TASK_ASSIGNED',
      'TASK_STATUS_CHANGED',
      'TASK_LOG_ADDED',
      'TASK_UPDATED',
      'LOGIN_SUCCESS',
      'LOGIN_FAILED'
    ]
  },

  // Who performed the action
  performedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  // Which project was affected (if applicable)
  project: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Project'
  },

  // Which task was affected (if applicable)
  task: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task'
  },

  // Which user was affected (if applicable, e.g., user created)
  affectedUser: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },

  // Additional details about the action
  details: {
    type: String
  },

  // When the action occurred
  timestamp: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: false // We use our own timestamp field
});

// Indexes for efficient filtering
activityLogSchema.index({ performedBy: 1, timestamp: -1 });
activityLogSchema.index({ project: 1, timestamp: -1 });
activityLogSchema.index({ task: 1, timestamp: -1 });
activityLogSchema.index({ timestamp: -1 });

module.exports = mongoose.model('ActivityLog', activityLogSchema);
