// config/db.js
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const Role = require("../models/Role");
const LogEntry = require("../models/LogEntry");

const connectDB = async () => {
  try {
    const mongoUri =
      process.env.MONGO_URI ||
      process.env.MONGODB_URI ||
      "mongodb://127.0.0.1:27017/auth-service";
    await mongoose.connect(mongoUri);
    console.log("✅ MongoDB connected");
    await initializeRolesAndAdmin();
  } catch (err) {
    console.error("❌ MongoDB connection error:", err.message);
    process.exit(1);
  }
};

const initializeRolesAndAdmin = async () => {
  try {
    // Define all available permissions
    const allPermissions = [
      "create_user",
      "delete_user",
      "create_role",
      "manage_roles",
      "assign_role",
      "manage_users",
      "view_logs",
      "manage_patients",
    ];

    // Create roles if they don't exist
    const roles = [
      {
        name: "Admin",
        permissions: allPermissions,
      },
      {
        name: "Doctor",
        permissions: ["manage_patients", "view_logs"],
      },
      {
        name: "Secretary",
        permissions: ["manage_patients"],
      },
      {
        name: "User",
        permissions: [],
      },
    ];

    for (const roleData of roles) {
      await Role.findOneAndUpdate(
        { name: roleData.name },
        { permissions: roleData.permissions },
        { upsert: true, new: true },
      );
    }

    // Get Admin role
    const adminRole = await Role.findOne({ name: "Admin" });
    if (!adminRole) {
      throw new Error("Failed to create Admin role");
    }

    // Create default admin if not exists
    const adminEmail = process.env.ADMIN_EMAIL || "admin@example.com";
    const defaultPassword = process.env.DEFAULT_ADMIN_PASSWORD || "changeme123";

    const adminExists = await User.findOne({ email: adminEmail });
    if (!adminExists) {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(defaultPassword, salt);

      const adminUser = new User({
        firstname: "System",
        lastname: "Admin",
        email: adminEmail,
        password: hashedPassword,
        role: adminRole._id,
        emailVerified: true,
      });

      await adminUser.save();

      // Log admin creation
      await LogEntry.create({
        eventType: "REGISTER",
        userId: adminUser._id,
        message: "Default admin account created during system initialization",
      });

      console.log(`✅ Default admin user created: ${adminEmail}`);
      console.log(
        "⚠️ IMPORTANT: Change the default admin password immediately!",
      );
    }
  } catch (error) {
    console.error("❌ System initialization error:", error.message);
  }
};

module.exports = connectDB;
