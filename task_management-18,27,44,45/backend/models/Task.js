/**
 * Task Model
 * Represents individual tasks within projects
 */

const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  // Task title
  title: {
    type: String,
    required: true,
    trim: true
  },

  // Task description/details
  description: {
    type: String,
    trim: true
  },

  // Which project this task belongs to
  project: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Project',
    required: true
  },

  // User assigned to complete this task
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },

  // Task status tracking
  status: {
    type: String,
    enum: ['pending', 'in-progress', 'completed', 'blocked'],
    default: 'pending'
  },

  // Task priority level
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },

  // Task deadline
  deadline: {
    type: Date
  },

  // Who created the task (manager or admin)
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
taskSchema.index({ project: 1 });
taskSchema.index({ assignedTo: 1 });
taskSchema.index({ status: 1 });
taskSchema.index({ deadline: 1 });

module.exports = mongoose.model('Task', taskSchema);
