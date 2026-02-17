/**
 * Notification Model
 * Stores in-app notifications for users
 */

const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  // Who should receive this notification
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  // Notification message content
  message: {
    type: String,
    required: true
  },

  // Type of notification (helps with filtering and UI display)
  type: {
    type: String,
    required: true,
    enum: [
      'task_assigned',
      'task_updated',
      'deadline_near',
      'project_assigned',
      'project_created',
      'project_updated',
      'project_deleted',
      'project_member_added',
      'member_added',
      'member_removed',
      'status_changed',
      'task_log_added',
      'due_soon',
      'task_created',
      'user_created',
      'user_deleted',
      'user_updated'
    ]
  },

  // Related task (if applicable)
  task: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task'
  },

  // Related project (if applicable)
  project: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Project'
  },

  // Whether user has read this notification
  isRead: {
    type: Boolean,
    default: false
  },

  // When notification was created
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries (especially for unread notifications)
notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
