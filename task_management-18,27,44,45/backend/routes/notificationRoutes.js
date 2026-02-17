/**
 * Notification Routes
 * Handles in-app notifications (backend-driven, no Firebase)
 */

const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { authenticate } = require('../middleware/authMiddleware');

/**
 * GET /api/notifications
 * Get notifications for current user
 * Frontend polls this endpoint every 10-15 seconds
 *
 * Query Parameters:
 * - unreadOnly: Return only unread notifications (default: false)
 * - limit: Number of notifications to return (default: 20)
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const { unreadOnly = 'false', limit = 20 } = req.query;

    let query = { userId: req.user._id };

    // Filter for unread only if requested
    if (unreadOnly === 'true') {
      query.isRead = false;
    }

    const notifications = await Notification.find(query)
      .populate('task', 'title')
      .populate('project', 'name')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    // Count unread notifications
    const unreadCount = await Notification.countDocuments({
      userId: req.user._id,
      isRead: false
    });

    res.json({
      count: notifications.length,
      unreadCount,
      notifications
    });

  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'Failed to fetch notifications', error: error.message });
  }
});

/**
 * PATCH /api/notifications/:id/read
 * Mark notification as read
 */
router.patch('/:id/read', authenticate, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    // Verify notification belongs to current user
    if (notification.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Access denied' });
    }

    notification.isRead = true;
    await notification.save();

    res.json({
      message: 'Notification marked as read',
      notification
    });

  } catch (error) {
    console.error('Mark notification read error:', error);
    res.status(500).json({ message: 'Failed to mark notification as read', error: error.message });
  }
});

/**
 * PATCH /api/notifications/mark-all-read
 * Mark all notifications as read for current user
 */
router.patch('/mark-all-read', authenticate, async (req, res) => {
  try {
    const result = await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { $set: { isRead: true } }
    );

    res.json({
      message: 'All notifications marked as read',
      modifiedCount: result.modifiedCount
    });

  } catch (error) {
    console.error('Mark all notifications read error:', error);
    res.status(500).json({ message: 'Failed to mark notifications as read', error: error.message });
  }
});

module.exports = router;
