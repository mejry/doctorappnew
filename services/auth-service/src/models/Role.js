const mongoose = require('mongoose');

const roleSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: [true, 'Role name is required'],
    unique: true
    // Removed enum restriction to allow custom role names
  },
  permissions: {
    type: [String],
    required: [true, 'Permissions are required'],
    // Remove the enum restriction so you can add any permission string
  },
   assignedUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }]
}, { timestamps: true });

module.exports = mongoose.model('Role', roleSchema);