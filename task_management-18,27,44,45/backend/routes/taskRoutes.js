/**
 * Task Routes
 * Handles task management with role-based permissions
 */

const express = require('express');
const router = express.Router();
const Task = require('../models/Task');
const TaskLog = require('../models/TaskLog');
const Project = require('../models/Project');
const ActivityLog = require('../models/ActivityLog');
const Notification = require('../models/Notification');
const { broadcastToAdmins } = require('../utils/broadcastToAdmins');
const { authenticate } = require('../middleware/authMiddleware');
const { checkRole } = require('../middleware/rbacMiddleware');

/**
 * GET /api/tasks
 * Get tasks based on user role
 * - Admin: All tasks
 * - Manager: Tasks in their projects
 * - Member: Tasks assigned to them
 */
router.get('/', authenticate, async (req, res) => {
  try {
    let tasks;

    if (req.user.role === 'admin') {
      // Admin sees all tasks
      tasks = await Task.find()
        .populate('project', 'name')
        .populate('assignedTo', 'name email')
        .populate('createdBy', 'name email')
        .sort({ createdAt: -1 });
    } else if (req.user.role === 'manager') {
      // Manager sees tasks in their projects
      const managerProjects = await Project.find({
        $or: [
          { manager: req.user._id },
          { members: req.user._id }
        ]
      }).select('_id');

      const projectIds = managerProjects.map(p => p._id);

      tasks = await Task.find({ project: { $in: projectIds } })
        .populate('project', 'name')
        .populate('assignedTo', 'name email')
        .populate('createdBy', 'name email')
        .sort({ createdAt: -1 });
    } else {
      // Members see only their assigned tasks
      tasks = await Task.find({ assignedTo: req.user._id })
        .populate('project', 'name')
        .populate('assignedTo', 'name email')
        .populate('createdBy', 'name email')
        .sort({ createdAt: -1 });

      // Create due_soon notifications for tasks due in next 24h (once per task per day)
      const now = Date.now();
      const oneDayMs = 24 * 60 * 60 * 1000;
      for (const t of tasks) {
        if (!t.deadline) continue;
        const dueTime = new Date(t.deadline).getTime();
        if (dueTime < now || dueTime > now + oneDayMs) continue;
        const existing = await Notification.findOne({
          userId: req.user._id,
          task: t._id,
          type: 'due_soon',
          createdAt: { $gte: new Date(now - oneDayMs) }
        });
        if (!existing) {
          await Notification.create({
            userId: req.user._id,
            message: `Task "${t.title}" is due in less than 24 hours`,
            type: 'due_soon',
            task: t._id,
            project: t.project?._id || t.project
          });
        }
      }
    }

    res.json({
      count: tasks.length,
      tasks
    });

  } catch (error) {
    console.error('Get tasks error:', error);
    res.status(500).json({ message: 'Failed to fetch tasks', error: error.message });
  }
});

/**
 * GET /api/tasks/:id/logs
 * Get progress log chain for a task. Manager (of project) or assignee only.
 */
router.get('/:id/logs', authenticate, async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('project', 'manager members')
      .populate('assignedTo', 'name email');
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    const proj = task.project;
    const managerId = proj.manager?._id?.toString() || proj.manager?.toString();
    const memberIds = (proj.members || []).map(m => m._id?.toString?.() || m.toString());
    const isManager = managerId === req.user._id.toString();
    const isMember = memberIds.includes(req.user._id.toString());
    const isAssignee = task.assignedTo && task.assignedTo._id.toString() === req.user._id.toString();
    if (req.user.role === 'admin') {
      // allow
    } else if (req.user.role === 'manager' && !isManager && !isMember) {
      return res.status(403).json({ message: 'Access denied to this task' });
    } else if (req.user.role === 'member' && !isAssignee) {
      return res.status(403).json({ message: 'Access denied to this task' });
    }

    const logs = await TaskLog.find({ task: req.params.id })
      .populate('performedBy', 'name email')
      .sort({ createdAt: 1 });
    res.json({ logs });
  } catch (error) {
    console.error('Get task logs error:', error);
    res.status(500).json({ message: 'Failed to fetch task logs', error: error.message });
  }
});

/**
 * POST /api/tasks/:id/logs
 * Add a progress log entry. Only the task assignee (member) can add logs; managers can view only.
 */
router.post('/:id/logs', authenticate, async (req, res) => {
  try {
    const { content, progressPercent, status: logStatus } = req.body;
    if (!content || typeof content !== 'string' || !content.trim()) {
      return res.status(400).json({ message: 'Content is required' });
    }

    const task = await Task.findById(req.params.id)
      .populate('project', 'name manager members')
      .populate('assignedTo', 'name email');
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    const isAssignee = task.assignedTo && task.assignedTo._id.toString() === req.user._id.toString();
    if (!isAssignee) {
      return res.status(403).json({ message: 'Only the task assignee (member) can add progress logs' });
    }

    const validStatuses = ['pending', 'in-progress', 'completed', 'blocked'];
    const newStatus = logStatus && validStatuses.includes(logStatus) ? logStatus : null;
    if (newStatus) {
      task.status = newStatus;
      await task.save();
    }
    const statusToStore = newStatus || task.status;

    const log = new TaskLog({
      task: task._id,
      performedBy: req.user._id,
      content: content.trim(),
      progressPercent: progressPercent != null ? Math.min(100, Math.max(0, Number(progressPercent))) : undefined,
      status: statusToStore
    });
    await log.save();
    await log.populate('performedBy', 'name email');

    await ActivityLog.create({
      action: 'TASK_LOG_ADDED',
      performedBy: req.user._id,
      project: task.project._id,
      task: task._id,
      details: `Progress log on task "${task.title}": ${content.trim().slice(0, 50)}${content.trim().length > 50 ? '...' : ''}`
    });

    if (proj.manager && proj.manager.toString() !== req.user._id.toString()) {
      await Notification.create({
        userId: proj.manager,
        message: `${req.user.name} added a progress update on task "${task.title}"`,
        type: 'task_log_added',
        task: task._id,
        project: task.project._id
      });
    }
    await broadcastToAdmins(
      `Progress update on task "${task.title}" by ${req.user.name}`,
      'task_log_added',
      { task: task._id, project: task.project._id }
    );

    res.status(201).json({ message: 'Log added', log });
  } catch (error) {
    console.error('Add task log error:', error);
    res.status(500).json({ message: 'Failed to add log', error: error.message });
  }
});

/**
 * GET /api/tasks/:id
 * Get single task. Manager: only tasks in their projects; Member: only tasks assigned to them; Admin: any (read-only).
 */
router.get('/:id', authenticate, async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('project', 'name manager members')
      .populate('assignedTo', 'name email')
      .populate('createdBy', 'name email');

    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (req.user.role === 'manager') {
      const proj = task.project;
      const managerId = proj.manager?._id?.toString() || proj.manager?.toString();
      const memberIds = (proj.members || []).map(m => m._id?.toString?.() || m.toString());
      if (managerId !== req.user._id.toString() && !memberIds.includes(req.user._id.toString())) {
        return res.status(403).json({ message: 'Access denied to this task' });
      }
    } else if (req.user.role === 'member') {
      if (!task.assignedTo || task.assignedTo._id.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: 'Access denied to this task' });
      }
    }

    res.json(task);
  } catch (error) {
    console.error('Get task error:', error);
    res.status(500).json({ message: 'Failed to fetch task', error: error.message });
  }
});

/**
 * PUT /api/tasks/:id
 * Update task (Manager only, for tasks in their projects). Body: title, description, projectId, assignedTo, priority, deadline, status.
 */
router.put('/:id', authenticate, checkRole(['manager']), async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('project', 'manager');
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    if (task.project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only edit tasks in projects you manage' });
    }

    const { title, description, projectId, assignedTo, priority, deadline, status } = req.body;
    if (title != null) task.title = title;
    if (description !== undefined) task.description = description;
    if (projectId != null) {
      const proj = await Project.findById(projectId);
      if (!proj) return res.status(404).json({ message: 'Project not found' });
      if (proj.manager.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: 'You can only assign to your projects' });
      }
      task.project = projectId;
    }
    if (assignedTo !== undefined) task.assignedTo = assignedTo || null;
    if (priority != null) task.priority = priority;
    if (deadline !== undefined) task.deadline = deadline || null;
    if (status != null) task.status = status;

    await task.save();
    await task.populate('project', 'name');
    await task.populate('assignedTo', 'name email');

    if (task.assignedTo && task.assignedTo._id.toString() !== req.user._id.toString()) {
      await Notification.create({
        userId: task.assignedTo._id,
        message: `Task "${task.title}" was updated`,
        type: 'task_updated',
        task: task._id,
        project: task.project._id
      });
    }
    await broadcastToAdmins(`Task "${task.title}" was updated`, 'task_updated', { task: task._id, project: task.project._id });

    res.json({ message: 'Task updated successfully', task });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({ message: 'Failed to update task', error: error.message });
  }
});

/**
 * DELETE /api/tasks/:id
 * Delete task (Manager only, for tasks in their projects).
 */
router.delete('/:id', authenticate, checkRole(['manager']), async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('project', 'manager');
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    if (task.project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only delete tasks in projects you manage' });
    }
    await Task.findByIdAndDelete(req.params.id);
    res.json({ message: 'Task deleted successfully' });
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({ message: 'Failed to delete task', error: error.message });
  }
});

/**
 * POST /api/tasks
 * Create new task (Manager only; admin does not create/assign tasks)
 * Supports multiple assignments - creates separate task for each assigned member
 *
 * Request Body:
 * {
 *   "title": "Task title",
 *   "description": "Task description",
 *   "projectId": "project_id",
 *   "assignedTo": ["user_id1", "user_id2"], // can be array or single ID
 *   "priority": "medium", // low, medium, high, urgent
 *   "deadline": "2024-12-31" // optional
 * }
 */
router.post('/', authenticate, checkRole(['manager']), async (req, res) => {
  try {
    const { title, description, projectId, assignedTo, priority, deadline } = req.body;

    // Validate input
    if (!title || !projectId) {
      return res.status(400).json({ message: 'Title and project are required' });
    }

    // Verify project exists
    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Manager can only create tasks in their projects
    if (req.user.role === 'manager' && project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only create tasks in projects you manage' });
    }

    // Handle multiple assignments - convert single to array
    const assignees = Array.isArray(assignedTo) ? assignedTo : (assignedTo ? [assignedTo] : []);
    const createdTasks = [];

    // If no assignees, create one unassigned task
    if (assignees.length === 0) {
      const task = new Task({
        title,
        description,
        project: projectId,
        assignedTo: null,
        priority: priority || 'medium',
        deadline: deadline || null,
        status: 'pending',
        createdBy: req.user._id
      });

      await task.save();
      createdTasks.push(task);

      // Log activity
      await ActivityLog.create({
        action: 'TASK_CREATED',
        performedBy: req.user._id,
        project: projectId,
        task: task._id,
        details: `Created task: ${task.title}`
      });

      if (project.manager && project.manager.toString() !== req.user._id.toString()) {
        await Notification.create({
          userId: project.manager,
          message: `New task created: ${task.title}`,
          type: 'task_created',
          task: task._id,
          project: projectId
        });
      }
      // Always notify the creator so they see "Task created" in their bell
      await Notification.create({
        userId: req.user._id,
        message: `Task created: ${task.title}`,
        type: 'task_created',
        task: task._id,
        project: projectId
      });
      await broadcastToAdmins(`Task created: ${task.title}`, 'task_created', { task: task._id, project: projectId });
    } else {
      // Create a separate task for each assignee
      for (const userId of assignees) {
        const task = new Task({
          title,
          description,
          project: projectId,
          assignedTo: userId,
          priority: priority || 'medium',
          deadline: deadline || null,
          status: 'pending',
          createdBy: req.user._id
        });

        await task.save();
        createdTasks.push(task);

        // Log activity for task creation
        await ActivityLog.create({
          action: 'TASK_CREATED',
          performedBy: req.user._id,
          project: projectId,
          task: task._id,
          details: `Created task: ${task.title}`
        });

        // Notify the assignee
        await Notification.create({
          userId: userId,
          message: `You have been assigned a new task: ${task.title}`,
          type: 'task_assigned',
          task: task._id,
          project: projectId
        });

        // Notify the creator so they see "Task created" in their bell
        await Notification.create({
          userId: req.user._id,
          message: `Task created: ${task.title}`,
          type: 'task_created',
          task: task._id,
          project: projectId
        });
        await broadcastToAdmins(`Task created: ${task.title}`, 'task_created', { task: task._id, project: projectId });

        // Log task assignment
        await ActivityLog.create({
          action: 'TASK_ASSIGNED',
          performedBy: req.user._id,
          project: projectId,
          task: task._id,
          affectedUser: userId,
          details: `Assigned task "${task.title}" to user`
        });
      }
    }

    // Populate the first task and return
    await createdTasks[0].populate('project', 'name');
    await createdTasks[0].populate('assignedTo', 'name email');
    await createdTasks[0].populate('createdBy', 'name email');

    res.status(201).json({
      message: `${createdTasks.length} task(s) created successfully`,
      task: createdTasks[0],
      tasksCreated: createdTasks.length
    });

  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({ message: 'Failed to create task', error: error.message });
  }
});

/**
 * PATCH /api/tasks/:id/status
 * Update task status (All roles can update status of tasks they can see)
 *
 * Request Body:
 * {
 *   "status": "in-progress" // pending, in-progress, completed, blocked
 * }
 */
router.patch('/:id/status', authenticate, async (req, res) => {
  try {
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }

    const task = await Task.findById(req.params.id)
      .populate('project', 'name manager members')
      .populate('assignedTo', 'name email');

    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    // Check permissions
    // Member: Can only update their own tasks
    if (req.user.role === 'member' &&
      (!task.assignedTo || task.assignedTo._id.toString() !== req.user._id.toString())) {
      return res.status(403).json({ message: 'You can only update tasks assigned to you' });
    }

    // Manager: Can update tasks in their projects
    if (req.user.role === 'manager') {
      const isManagerOfProject = task.project.manager.toString() === req.user._id.toString();
      const isMemberOfProject = task.project.members.some(m => m.toString() === req.user._id.toString());

      if (!isManagerOfProject && !isMemberOfProject) {
        return res.status(403).json({ message: 'You can only update tasks in your projects' });
      }
    }

    const oldStatus = task.status;
    task.status = status;
    await task.save();

    // Log activity
    await ActivityLog.create({
      action: 'TASK_STATUS_CHANGED',
      performedBy: req.user._id,
      project: task.project._id,
      task: task._id,
      details: `Changed task status from "${oldStatus}" to "${status}": ${task.title}`
    });

    // Notify project manager if member changed status
    if (req.user.role === 'member' && task.project.manager.toString() !== req.user._id.toString()) {
      await Notification.create({
        userId: task.project.manager,
        message: `Task "${task.title}" status changed to ${status}`,
        type: 'status_changed',
        task: task._id,
        project: task.project._id
      });
    }
    await broadcastToAdmins(`Task "${task.title}" status changed to ${status}`, 'status_changed', { task: task._id, project: task.project._id });

    res.json({
      message: 'Task status updated successfully',
      task
    });

  } catch (error) {
    console.error('Update task status error:', error);
    res.status(500).json({ message: 'Failed to update task status', error: error.message });
  }
});

/**
 * PATCH /api/tasks/:id/assign
 * Assign task to user (Admin and Manager only)
 *
 * Request Body:
 * {
 *   "userId": "user_id_to_assign"
 * }
 */
router.patch('/:id/assign', authenticate, checkRole(['manager']), async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }

    const task = await Task.findById(req.params.id).populate('project');
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    // Manager can only assign tasks in their projects
    if (req.user.role === 'manager' && task.project.manager.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You can only assign tasks in projects you manage' });
    }

    task.assignedTo = userId;
    await task.save();

    // Log activity
    await ActivityLog.create({
      action: 'TASK_ASSIGNED',
      performedBy: req.user._id,
      project: task.project._id,
      task: task._id,
      affectedUser: userId,
      details: `Assigned task: ${task.title}`
    });

    // Notify the assigned user
    await Notification.create({
      userId: userId,
      message: `You have been assigned to task: ${task.title}`,
      type: 'task_assigned',
      task: task._id,
      project: task.project._id
    });
    await broadcastToAdmins(`Task "${task.title}" assigned to user`, 'task_assigned', { task: task._id, project: task.project._id });

    await task.populate('assignedTo', 'name email');

    res.json({
      message: 'Task assigned successfully',
      task
    });

  } catch (error) {
    console.error('Assign task error:', error);
    res.status(500).json({ message: 'Failed to assign task', error: error.message });
  }
});

module.exports = router;
