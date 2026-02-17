/**
 * Broadcast a copy of an activity notification to all admins
 * so admins see all activity (tasks, projects, members) in their notification panel.
 */

const User = require('../models/User');
const Notification = require('../models/Notification');

/**
 * @param {string} message
 * @param {string} type
 * @param {{ task?: ObjectId, project?: ObjectId }} refs
 */
async function broadcastToAdmins(message, type, refs = {}) {
  const admins = await User.find({ role: 'admin' }).select('_id');
  if (admins.length === 0) return;
  await Notification.insertMany(
    admins.map((a) => ({
      userId: a._id,
      message,
      type,
      task: refs.task || undefined,
      project: refs.project || undefined
    }))
  );
}

module.exports = { broadcastToAdmins };
