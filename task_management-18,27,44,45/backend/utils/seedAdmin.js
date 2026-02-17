/**
 * Admin User Seeding Utility
 * Creates the default admin user on first startup
 */

const User = require('../models/User');
const bcrypt = require('bcryptjs');

/**
 * Creates admin user if it doesn't exist
 * Uses credentials from .env file
 */
const seedAdminUser = async () => {
  try {
    // Check if admin user already exists
    const adminExists = await User.findOne({ email: process.env.ADMIN_EMAIL });

    if (adminExists) {
      console.log('ℹ️  Admin user already exists');
      return;
    }

    // Hash the admin password
    const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);

    // Create admin user
    const admin = new User({
      name: 'System Administrator',
      email: process.env.ADMIN_EMAIL,
      password: hashedPassword,
      role: 'admin',
      isActive: true
    });

    await admin.save();
    console.log('✅ Admin user created successfully');
    console.log(`   Email: ${process.env.ADMIN_EMAIL}`);
    console.log(`   Password: ${process.env.ADMIN_PASSWORD}`);
  } catch (error) {
    console.error('❌ Error seeding admin user:', error.message);
  }
};

module.exports = { seedAdminUser };
