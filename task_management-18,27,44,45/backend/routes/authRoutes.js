/**
 * Authentication Routes
 * Handles user login and JWT token generation
 */

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');

/**
 * POST /api/auth/login
 * Login endpoint - validates credentials and returns JWT token
 *
 * Request Body:
 * {
 *   "email": "user@example.com",
 *   "password": "password123"
 * }
 *
 * Response:
 * {
 *   "token": "jwt_token_here",
 *   "user": { id, name, email, role }
 * }
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      // Log failed login attempt
      await ActivityLog.create({
        action: 'LOGIN_FAILED',
        performedBy: null,
        details: `Failed login attempt for email: ${email}`
      }).catch(() => { }); // Don't fail if logging fails

      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(403).json({ message: 'Account is deactivated' });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      // Log failed login attempt
      await ActivityLog.create({
        action: 'LOGIN_FAILED',
        performedBy: user._id,
        details: `Failed login attempt - incorrect password`
      }).catch(() => { });

      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Generate JWT token (expires in 7 days)
    const token = jwt.sign(
      {
        userId: user._id,
        role: user.role
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Log successful login
    await ActivityLog.create({
      action: 'LOGIN_SUCCESS',
      performedBy: user._id,
      details: `User logged in successfully`
    }).catch(() => { });

    // Return token and user info (excluding password)
    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
});

module.exports = router;
