/**
 * TaskLog Model
 * Progress/version-control style logs for a task (member updates, progress notes)
 */

const mongoose = require('mongoose');

const taskLogSchema = new mongoose.Schema({
  task: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task',
    required: true
  },
  performedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    required: true,
    trim: true
  },
  progressPercent: {
    type: Number,
    min: 0,
    max: 100,
    default: null
  },
  status: {
    type: String,
    enum: ['pending', 'in-progress', 'completed', 'blocked'],
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

taskLogSchema.index({ task: 1, createdAt: -1 });

module.exports = mongoose.model('TaskLog', taskLogSchema);
