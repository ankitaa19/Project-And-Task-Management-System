/**
 * User Routes
 * Handles user management (Admin only)
 */

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const Notification = require('../models/Notification');
const { authenticate } = require('../middleware/authMiddleware');
const { checkRole } = require('../middleware/rbacMiddleware');

/** Notify all admins about an activity (including the one who performed it, so the bell shows something) */
async function notifyAdmins(message, type) {
  const admins = await User.find({ role: 'admin' }).select('_id');
  if (admins.length === 0) return;
  await Notification.insertMany(
    admins.map(a => ({ userId: a._id, message, type }))
  );
}

/**
 * GET /api/users
 * Get users based on role:
 * - Admin: sees all users
 * - Manager: sees only members
 */
router.get('/', authenticate, checkRole(['admin', 'manager']), async (req, res) => {
  try {
    let users;

    if (req.user.role === 'admin') {
      // Admin sees all users
      users = await User.find().select('-password').sort({ createdAt: -1 });
    } else if (req.user.role === 'manager') {
      // Manager sees only members
      users = await User.find({ role: 'member' }).select('-password').sort({ createdAt: -1 });
    }

    res.json({
      count: users.length,
      users
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Failed to fetch users', error: error.message });
  }
});

/**
 * POST /api/users
 * Create new user (Admin only)
 *
 * Request Body:
 * {
 *   "name": "John Doe",
 *   "email": "john@example.com",
 *   "password": "password123",
 *   "role": "member" // admin, manager, or member
 * }
 */
router.post('/', authenticate, checkRole(['admin']), async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    // Validate input
    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    // Validate role
    if (!['admin', 'manager', 'member'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = new User({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      role,
      isActive: true
    });

    await newUser.save();

    // Log activity
    await ActivityLog.create({
      action: 'USER_CREATED',
      performedBy: req.user._id,
      affectedUser: newUser._id,
      details: `Created new user: ${newUser.name} (${newUser.role})`
    });

    await notifyAdmins(
      `New user created: ${newUser.name} (${newUser.role})`,
      'user_created'
    );

    // Return user without password
    const userResponse = newUser.toObject();
    delete userResponse.password;

    res.status(201).json({
      message: 'User created successfully',
      user: userResponse
    });

  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ message: 'Failed to create user', error: error.message });
  }
});

/**
 * DELETE /api/users/:id
 * Delete a user permanently (Admin only)
 */
router.delete('/:id', authenticate, checkRole(['admin']), async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Prevent admin from deleting their own account
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ message: 'Cannot delete your own account' });
    }

    const userName = user.name;
    const userEmail = user.email;

    await User.findByIdAndDelete(req.params.id);

    // Log activity
    await ActivityLog.create({
      action: 'USER_DELETED',
      performedBy: req.user._id,
      affectedUser: user._id,
      details: `Deleted user: ${userName} (${userEmail})`
    });

    await notifyAdmins(
      `User deleted: ${userName} (${userEmail})`,
      'user_deleted'
    );

    res.json({
      message: 'User deleted successfully',
      deletedUserId: req.params.id
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Failed to delete user', error: error.message });
  }
});

/**
 * PATCH /api/users/:id/toggle-status
 * Activate or deactivate user (Admin only)
 */
router.patch('/:id/toggle-status', authenticate, checkRole(['admin']), async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Prevent admin from deactivating themselves
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ message: 'Cannot deactivate your own account' });
    }

    // Toggle active status
    user.isActive = !user.isActive;
    await user.save();

    // Log activity
    await ActivityLog.create({
      action: 'USER_UPDATED',
      performedBy: req.user._id,
      affectedUser: user._id,
      details: `User ${user.isActive ? 'activated' : 'deactivated'}: ${user.name}`
    });

    await notifyAdmins(
      `User ${user.isActive ? 'activated' : 'deactivated'}: ${user.name}`,
      'user_updated'
    );

    res.json({
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isActive: user.isActive
      }
    });

  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({ message: 'Failed to update user status', error: error.message });
  }
});

module.exports = router;
