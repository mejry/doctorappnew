const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Role = require('../models/Role');
const LogEntry = require('../models/LogEntry');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
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
      
      // Prescription management
      'view_prescription',
      'create_prescription',
      'update_prescription',
      'delete_prescription' ,
       // Prescription management
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
          'update_consultation'
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
          'update_consultation'
        ] 
      },
      { 
        name: 'Receptionist', 
    permissions: [
          'view_patient',
          'create_patient',
          'update_patient'
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
        firstname: 'roua',
        lastname: 'youneb',
        email: adminEmail,
        password: defaultPassword,
        role: adminRole._id,
        emailVerified: true,
        active: true 
      });
       
      
      await adminUser.save();
      
      // Log admin creation
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
  } catch (error) {
    console.error('❌ System initialization error:', error.message);
  }
};

module.exports = connectDB;