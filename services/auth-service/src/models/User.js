// models/User.js - Version simple avec rôles multiples
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const validator = require('validator');

const userSchema = new mongoose.Schema({
  email: { 
    type: String, 
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: [validator.isEmail, 'Invalid email format']
  },
  password: { 
    type: String, 
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters']
  },
  firstname: { 
    type: String, 
    required: [true, 'First name is required'],
    trim: true 
  },
  lastname: { 
    type: String, 
    required: [true, 'Last name is required'],
    trim: true 
  },
  specialite: { 
    type: String,
    required: false
  },
  // ✅ Garder l'ancien système pour compatibilité
  role: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Role', 
    required: true 
  },
  passwordChangedAt: {
  type: Date,
  default: Date.now
},
  // ✅ Ajouter les rôles multiples (optionnel)
  additionalRoles: [{
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Role'
  }],
  twoFactorCode: String,
  twoFactorExpires: Date,
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  emailVerified: { type: Boolean, default: false },
  twoFactorEnabled: { type: Boolean, default: false },
  lastLogin: Date,
  active: { type: Boolean, default: true }
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    this.password = await bcrypt.hash(this.password, 10);
    next();
  } catch (error) {
    next(error);
  }
});

// ✅ Méthode pour obtenir toutes les permissions de l'utilisateur
userSchema.methods.getAllPermissions = function() {
  if (!this.populated('role') && !this.populated('additionalRoles')) {
    return [];
  }
  
  const allPermissions = new Set();
  
  // Permissions du rôle principal
  if (this.role && this.role.permissions) {
    this.role.permissions.forEach(permission => {
      allPermissions.add(permission);
    });
  }
  
  // Permissions des rôles additionnels
  if (this.additionalRoles && Array.isArray(this.additionalRoles)) {
    this.additionalRoles.forEach(role => {
      if (role.permissions && Array.isArray(role.permissions)) {
        role.permissions.forEach(permission => {
          allPermissions.add(permission);
        });
      }
    });
  }
  
  return Array.from(allPermissions);
};

// ✅ Méthode pour vérifier si l'utilisateur a une permission
userSchema.methods.hasPermission = function(permission) {
  const allPermissions = this.getAllPermissions();
  return allPermissions.includes(permission);
};

// ✅ Méthode pour obtenir les noms des rôles
userSchema.methods.getAllRoleNames = function() {
  const roleNames = [];
  
  if (this.role && this.role.name) {
    roleNames.push(this.role.name);
  }
  
  if (this.additionalRoles && Array.isArray(this.additionalRoles)) {
    this.additionalRoles.forEach(role => {
      if (role.name) {
        roleNames.push(role.name);
      }
    });
  }
  
  return roleNames;
};

// Add method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Method to return user data without sensitive fields
userSchema.methods.toJSON = function() {
  const userObject = this.toObject();
  delete userObject.password;
  delete userObject.twoFactorCode;
  delete userObject.resetPasswordToken;
  delete userObject.resetPasswordExpires;
  
  // ✅ Include permissions and role names in response
  userObject.allPermissions = this.getAllPermissions();
  userObject.allRoleNames = this.getAllRoleNames();
  
  return userObject;
};

module.exports = mongoose.model('User', userSchema);