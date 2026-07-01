const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Role = require('../models/Role');
const LogEntry = require('../models/LogEntry');

const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/auth-service';
    await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 5000
    });
    console.log('✅ MongoDB connected');
    await initializeRolesAndAdmin();
  } catch (err) {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  }
};

const initializeRolesAndAdmin = async () => {
  try {
    // Define all available permissions
    const allPermissions = [
      // User management
      'view_user',
      'create_user',
      'update_user',
      'delete_user',

      // Role management
      'view_role',
      'create_role',
      'update_role',
      'delete_role',

      // Patient management
      'view_patient',
      'create_patient',
      'update_patient',
      'delete_patient',

      // Consultation management
      'view_consultation',
      'create_consultation',
      'update_consultation',
      'delete_consultation',

      // Appointment management
      'view_appointment',
      'create_appointment',
      'update_appointment',
      'delete_appointment',

      'view_prescription',
      'create_prescription',
      'update_prescription',
      'delete_prescription',
      // Medication management
      'view_medication',
      'create_medication',
      'update_medication',
      'delete_medication',
    ];

    // Create roles with specific permissions
    const roles = [
      {
        name: 'Admin',
        permissions: allPermissions
      },
      {
        name: 'Doctor',
        permissions: [
          'view_patient',
          'create_patient',
          'update_patient',
          'view_consultation',
          'create_consultation',
          'update_consultation',
          'view_appointment',
          'create_appointment',
          'update_appointment'
        ]
      },
      {
        name: 'Secretary',
        permissions: [
          'view_patient',
          'create_patient',
          'update_patient',
          'view_consultation',
          'create_consultation',
          'update_consultation',
          'view_appointment',
          'create_appointment',
          'update_appointment'
        ]
      },
      {
        name: 'Receptionist',
        permissions: [
          'view_patient',
          'create_patient',
          'update_patient',
          'view_appointment',
          'create_appointment',
          'update_appointment'
        ]
      },
      {
        name: 'User',
        permissions: []
      }
    ];


    for (const roleData of roles) {
      await Role.findOneAndUpdate(
        { name: roleData.name },
        { permissions: roleData.permissions },
        { upsert: true, new: true }
      );
    }

    // Get Admin role
    const adminRole = await Role.findOne({ name: 'Admin' });
    if (!adminRole) {
      throw new Error('Failed to create Admin role');
    }

    // Create default admin if not exists
    const adminEmail = process.env.ADMIN_EMAIL || 'mejriaziz917@gmail.com';
    const defaultPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'azizmejri';
    console.log(defaultPassword);
    const adminExists = await User.findOne({ email: adminEmail });
    console.log(adminEmail);
    console.log(adminExists);


    if (!adminExists) {

      //const hashedPassword = await bcrypt.hash(defaultPassword, 10);

      const adminUser = new User({
        firstname: 'mejriaziz',
        lastname: 'mejriaziz',
        email: adminEmail,
        password: defaultPassword,
        role: adminRole._id,
        emailVerified: true,
        active: true
      });


      await adminUser.save();

      await LogEntry.create({
        eventType: 'REGISTER',
        action: 'CREATE_ADMIN',  // Add this required field
        userId: adminUser._id,
        message: 'Default admin account created during system initialization'
      });

      console.log(`✅ Default admin user created: ${adminEmail}`);
      console.log('⚠️ IMPORTANT: Change the default admin password immediately!');
    } else {
      // FIXED: Ensure existing admin is active
      if (adminExists.active !== true) {
        adminExists.active = true;
        await adminExists.save();
        console.log(`✅ Default admin user updated: ${adminEmail}`);
      }
    }

    // CREATE DEFAULT SECRETARY
    const secretaryRole = await Role.findOne({ name: 'Secretary' });
    if (secretaryRole) {
      const secEmail = 'manitayounes290@gmail.com';
      const secPassword = 'password123';
      const secExists = await User.findOne({ email: secEmail });
      if (!secExists) {
        const secUser = new User({
          firstname: 'Demo',
          lastname: 'Secretaire',
          email: secEmail,
          password: secPassword,
          role: secretaryRole._id,
          emailVerified: true,
          active: true
        });
        await secUser.save();
        console.log(`✅ Default secretary user created: ${secEmail}`);
      }
    }

    // CREATE DEFAULT USER
    const userRole = await Role.findOne({ name: 'User' });
    if (userRole) {
      const usrEmail = 'user@example.com';
      const usrPassword = 'password123';
      const usrExists = await User.findOne({ email: usrEmail });
      if (!usrExists) {
        const usrUser = new User({
          firstname: 'Demo',
          lastname: 'User',
          email: usrEmail,
          password: usrPassword,
          role: userRole._id,
          emailVerified: true,
          active: true
        });
        await usrUser.save();
        console.log(`✅ Default user created: ${usrEmail}`);
      }
    }

  } catch (error) {
    console.error('❌ System initialization error:', error.message);
  }
};

module.exports = connectDB;
