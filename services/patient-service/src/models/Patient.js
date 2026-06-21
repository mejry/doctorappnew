const mongoose = require('mongoose');

const PatientSchema = new mongoose.Schema({
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  gender: { type: String, enum: ['Male', 'Female', 'Other'], required: true },
  dob: { type: Date, required: true },
  address: { type: String },
  civilStatus: { 
    type: String, 
    enum: ['Single', 'Married', 'Divorced', 'Widowed'] 
  },
  phoneNumber: { type: String },
  emergencyContacts: [{
    name: String,
    phone: String,
    relationship: String
  }],
  dateOfRegistration: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Patient', PatientSchema);