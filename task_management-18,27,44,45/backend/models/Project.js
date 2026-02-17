/**
 * Project Model
 * Represents projects that contain tasks
 */

const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  // Project name
  name: {
    type: String,
    required: true,
    trim: true
  },

  // Project description
  description: {
    type: String,
    trim: true
  },

  // Manager assigned to this project
  manager: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // References User model
    required: true
  },

  // Array of team members (excluding manager)
  members: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],

  // Project status
  status: {
    type: String,
    enum: ['active', 'completed', 'on-hold'],
    default: 'active'
  },

  // Who created the project (usually admin or manager)
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

// Indexes for faster queries
projectSchema.index({ manager: 1 });
projectSchema.index({ members: 1 });
projectSchema.index({ status: 1 });

module.exports = mongoose.model('Project', projectSchema);
