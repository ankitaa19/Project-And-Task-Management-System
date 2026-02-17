/**
 * Activity Log Routes
 * Handles fetching activity logs with role-based filtering
 */

const express = require('express');
const router = express.Router();
const ActivityLog = require('../models/ActivityLog');
const { authenticate } = require('../middleware/authMiddleware');

/**
 * GET /api/activity-logs
 * Login audit only: returns only LOGIN_SUCCESS and LOGIN_FAILED.
 * - Admin: All login logs
 * - Manager/Member: Only their own login attempts
 *
 * Query Parameters:
 * - limit: Number of logs to return (default 50)
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const { limit = 50 } = req.query;
    const query = { action: { $in: ['LOGIN_SUCCESS', 'LOGIN_FAILED'] } };

    if (req.user.role !== 'admin') {
      query.performedBy = req.user._id;
    }

    const logs = await ActivityLog.find(query)
      .populate('performedBy', 'name email role')
      .populate('project', 'name')
      .populate('task', 'title')
      .populate('affectedUser', 'name email')
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json({
      count: logs.length,
      logs
    });

  } catch (error) {
    console.error('Get activity logs error:', error);
    res.status(500).json({ message: 'Failed to fetch activity logs', error: error.message });
  }
});

module.exports = router;
