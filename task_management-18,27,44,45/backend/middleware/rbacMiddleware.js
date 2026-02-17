/**
 * Role-Based Access Control (RBAC) Middleware
 * This middleware checks if user has required role to access a route
 */

/**
 * Check if user has one of the allowed roles
 * @param {Array} allowedRoles - Array of roles that can access the route
 * @returns Middleware function
 *
 * Usage: checkRole(['admin', 'manager'])
 */
const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    // req.user is set by authenticate middleware
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    // Check if user's role is in the allowed roles array
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: 'Access denied. Insufficient permissions.',
        requiredRole: allowedRoles,
        userRole: req.user.role
      });
    }

    // User has required role, proceed to route handler
    next();
  };
};

module.exports = { checkRole };
