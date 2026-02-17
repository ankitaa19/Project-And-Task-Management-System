/**
 * Project Routes
 * Handles project management
 */

const express = require('express');
const router = express.Router();
const Project = require('../models/Project');
const Task = require('../models/Task');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const Notification = require('../models/Notification');
const { broadcastToAdmins } = require('../utils/broadcastToAdmins');
const { authenticate } = require('../middleware/authMiddleware');
const { checkRole } = require('../middleware/rbacMiddleware');

/**
 * GET /api/projects
 * Get projects based on user role
 * - Admin: All projects
 * - Manager: Projects they manage or are members of
 * - Member: Projects they are members of
 */
router.get('/', authenticate, async (req, res) => {
  try {
    let projects;

    if (req.user.role === 'admin') {
      // Admin sees all projects
      projects = await Project.find()
        .populate('manager', 'name email role')
        .populate('members', 'name email role')
        .populate('createdBy', 'name email')
        .sort({ createdAt: -1 });
    } else if (req.user.role === 'manager') {
      // Manager sees projects they manage or are members of
      projects = await Project.find({
        $or: [
          { manager: req.user._id },
          { members: req.user._id }
        ]
      })
        .populate('manager', 'name email role')
        .populate('members', 'name email role')
        .populate('createdBy', 'name email')
        .sort({ createdAt: -1 });
    } else {
      // Members see only projects they're part of
      projects = await Project.find({ members: req.user._id })
        .populate('manager', 'name email role')
        .populate('members', 'name email role')
        .populate('createdBy', 'name email')
        .sort({ createdAt: -1 });
    }

    res.json({
      count: projects.length,
      projects
    });

  } catch (error) {
    console.error('Get projects error:', error);
    res.status(500).json({ message: 'Failed to fetch projects', error: error.message });
  }
});

/**
 * GET /api/projects/:id
 * Get single project by ID (for detail/edit). Admin: any; Manager: own projects only; Member: if in members.
 */
router.get('/:id', authenticate, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id)
      .populate('manager', 'name email role')
      .populate('members', 'name email role')
      .populate('createdBy', 'name email');

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    if (req.user.role === 'manager' && project.manager._id.toString() !== req.user._id.toString()) {
      const isMember = project.members.some(m => m._id.toString() === req.user._id.toString());
      if (!isMember) {
        return res.status(403).json({ message: 'Access denied to this project' });
      }
    }
    if (req.user.role === 'member') {
      const isMember = project.members.some(m => m._id.toString() === req.user._id.toString());
      if (!isMember) {
        return res.status(403).json({ message: 'Access denied to this project' });
      }
    }

    res.json(project);
  } catch (error) {
    console.error('Get project error:', error);
    res.status(500).json({ message: 'Failed to fetch project', error: error.message });
  }
});

/**
 * POST /api/projects
 * Create new project (Admin and Manager only)
 *
 * Request Body:
 * {
 *   "name": "Project Name",
 *   "description": "Project description",
 *   "managerId": "manager_user_id",
 *   "members": ["user_id1", "user_id2"], // optional array of member IDs
 *   "status": "active" // optional: active, on-hold, completed
 * }
 */
router.post('/', authenticate, checkRole(['admin', 'manager']), async (req, res) => {
  try {
    const { name, description, managerId, members, status } = req.body;

    // Validate input
    if (!name || !managerId) {
      return res.status(400).json({ message: 'Name and manager are required' });
    }

    // Verify manager exists and has correct role
    const manager = await User.findById(managerId);
    if (!manager) {
      return res.status(404).json({ message: 'Manager not found' });
    }
    if (manager.role !== 'manager' && manager.role !== 'admin') {
      return res.status(400).json({ message: 'Selected user is not a manager' });
    }

    // Validate members if provided
    const memberIds = members && Array.isArray(members) ? members : [];
    if (memberIds.length > 0) {
      const validMembers = await User.find({ _id: { $in: memberIds } });
      if (validMembers.length !== memberIds.length) {
        return res.status(400).json({ message: 'One or more member IDs are invalid' });
      }
    }

    // Create project
    const project = new Project({
      name,
      description,
      manager: managerId,
      members: memberIds,
      status: status || 'active',
      createdBy: req.user._id
    });

    await project.save();

    // Log activity
    await ActivityLog.create({
      action: 'PROJECT_CREATED',
      performedBy: req.user._id,
      project: project._id,
      details: `Created project: ${project.name} with ${memberIds.length} members`
    });

    // Notify manager if they didn't create it
    if (managerId !== req.user._id.toString()) {
      await Notification.create({
        userId: managerId,
        message: `You have been assigned as manager for project: ${project.name}`,
        type: 'project_assigned',
        project: project._id
      });
    }

    // Notify all added members
    if (memberIds.length > 0) {
      const memberNotifications = memberIds.map(memberId => ({
        userId: memberId,
        message: `You have been added to project: ${project.name}`,
        type: 'project_member_added',
        project: project._id
      }));
      await Notification.insertMany(memberNotifications);
    }
    await broadcastToAdmins(`Project created: ${project.name}`, 'project_created', { project: project._id });

    // Populate and return
    await project.populate('manager', 'name email');
    await project.populate('members', 'name email role');
    await project.populate('createdBy', 'name email');

    res.status(201).json({
      message: 'Project created successfully',
      project
    });

  } catch (error) {
    console.error('Create project error:', error);
    res.status(500).json({ message: 'Failed to create project', error: error.message });
  }
});

/**
 * DELETE /api/projects/:id
 * Delete project and all its tasks. Admin only.
 */
router.delete('/:id', authenticate, checkRole(['admin']), async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }
    // Notify admins before deleting (so we still have project name/id)
    await broadcastToAdmins(`Project "${project.name}" was deleted`, 'project_deleted', { project: project._id });
    await Task.deleteMany({ project: req.params.id });
    await Project.findByIdAndDelete(req.params.id);
    res.json({ message: 'Project deleted successfully' });
  } catch (error) {
    console.error('Delete project error:', error);
    res.status(500).json({ message: 'Failed to delete project', error: error.message });
  }
});

/**
 * PUT /api/projects/:id
 * Update project details (Admin and Manager of project)
 */
router.put('/:id', authenticate, checkRole(['admin', 'manager']), async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Manager can only update their own projects, and only status (not name, description, manager, members)
    if (req.user.role === 'manager') {
      if (project.manager.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: 'You can only update projects you manage' });
      }
      const { status } = req.body;
      if (status) project.status = status;
      await project.save();

      await ActivityLog.create({
        action: 'PROJECT_UPDATED',
        performedBy: req.user._id,
        project: project._id,
        details: `Updated project status: ${project.name}`
      });
      const notifyIds = [project.manager, ...project.members].filter(
        id => id && id.toString() !== req.user._id.toString()
      );
      if (notifyIds.length > 0) {
        await Notification.insertMany(
          notifyIds.map(uid => ({
            userId: uid,
            message: `Project "${project.name}" was updated`,
            type: 'project_updated',
            project: project._id
          }))
        );
      }
      await broadcastToAdmins(`Project "${project.name}" was updated`, 'project_updated', { project: project._id });

      await project.populate('manager', 'name email');
      await project.populate('members', 'name email');
      return res.json({
        message: 'Project updated successfully',
        project
      });
    }

    const { name, description, status, managerId, members } = req.body;

    // Admin: update all fields
    if (name) project.name = name;
    if (description !== undefined) project.description = description;
    if (status) project.status = status;

    if (managerId != null) {
      const manager = await User.findById(managerId);
      if (!manager) {
        return res.status(404).json({ message: 'Manager not found' });
      }
      if (manager.role !== 'manager' && manager.role !== 'admin') {
        return res.status(400).json({ message: 'Selected user is not a manager' });
      }
      project.manager = managerId;
    }

    if (members !== undefined && Array.isArray(members)) {
      const validMembers = await User.find({ _id: { $in: members } });
      if (validMembers.length !== members.length) {
        return res.status(400).json({ message: 'One or more member IDs are invalid' });
      }
      project.members = members;
    }

    await project.save();

    // Log activity
    await ActivityLog.create({
      action: 'PROJECT_UPDATED',
      performedBy: req.user._id,
      project: project._id,
      details: `Updated project: ${project.name}`
    });

    const notifyIds = [project.manager, ...project.members].filter(
      id => id && id.toString() !== req.user._id.toString()
    );
    if (notifyIds.length > 0) {
      await Notification.insertMany(
        notifyIds.map(uid => ({
          userId: uid,
          message: `Project "${project.name}" was updated`,
          type: 'project_updated',
          project: project._id
        }))
      );
    }
    await broadcastToAdmins(`Project "${project.name}" was updated`, 'project_updated', { project: project._id });

    await project.populate('manager', 'name email');
    await project.populate('members', 'name email');

    res.json({
      message: 'Project updated successfully',
      project
    });

  } catch (error) {
    console.error('Update project error:', error);
    res.status(500).json({ message: 'Failed to update project', error: error.message });
  }
});

/**
 * POST /api/projects/:id/add-member
 * Add member to project
 *
 * Request Body:
 * {
 *   "userId": "user_id_to_add"
 * }
 */
router.post('/:id/add-member', authenticate, checkRole(['admin', 'manager']), async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }

    const project = await Project.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Manager can only add to their own projects
    if (req.user.role === 'manager' && project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only add members to projects you manage' });
    }

    // Verify user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if already a member
    if (project.members.includes(userId)) {
      return res.status(400).json({ message: 'User is already a member of this project' });
    }

    // Add member
    project.members.push(userId);
    await project.save();

    // Log activity
    await ActivityLog.create({
      action: 'MEMBER_ADDED',
      performedBy: req.user._id,
      project: project._id,
      affectedUser: userId,
      details: `Added ${user.name} to project: ${project.name}`
    });

    // Notify the added member
    await Notification.create({
      userId: userId,
      message: `You have been added to project: ${project.name}`,
      type: 'member_added',
      project: project._id
    });

    // Notify project manager so they see "my team" updates (if different from who added)
    if (project.manager && project.manager.toString() !== req.user._id.toString()) {
      await Notification.create({
        userId: project.manager,
        message: `Member ${user.name} added to project ${project.name}`,
        type: 'member_added',
        project: project._id
      });
    }
    await broadcastToAdmins(`Member ${user.name} added to project ${project.name}`, 'member_added', { project: project._id });

    await project.populate('members', 'name email');

    res.json({
      message: 'Member added successfully',
      project
    });

  } catch (error) {
    console.error('Add member error:', error);
    res.status(500).json({ message: 'Failed to add member', error: error.message });
  }
});

/**
 * DELETE /api/projects/:id/remove-member/:userId
 * Remove member from project
 */
router.delete('/:id/remove-member/:userId', authenticate, checkRole(['admin', 'manager']), async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Manager can only remove from their own projects
    if (req.user.role === 'manager' && project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only remove members from projects you manage' });
    }

    // Remove member
    project.members = project.members.filter(m => m.toString() !== req.params.userId);
    await project.save();

    // Log activity
    await ActivityLog.create({
      action: 'MEMBER_REMOVED',
      performedBy: req.user._id,
      project: project._id,
      affectedUser: req.params.userId,
      details: `Removed member from project: ${project.name}`
    });

    await Notification.create({
      userId: req.params.userId,
      message: `You were removed from project: ${project.name}`,
      type: 'member_removed',
      project: project._id
    });
    await broadcastToAdmins(`Member removed from project: ${project.name}`, 'member_removed', { project: project._id });

    res.json({
      message: 'Member removed successfully',
      project
    });

  } catch (error) {
    console.error('Remove member error:', error);
    res.status(500).json({ message: 'Failed to remove member', error: error.message });
  }
});

module.exports = router;
