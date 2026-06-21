const mongoose = require('mongoose');
const { Schema } = mongoose;

const PrescriptionSchema = new Schema({
  // 1. CORE PRESCRIPTION INFO
  prescriptionInfo: {
    type: {
      type: String,
      enum: ['Regular', 'Emergency', 'Hospital', 'Discharge', 'Renewal'],
      required: true,
      default: 'Regular'
    },
    status: {
      type: String,
      enum: ['Active', 'Completed', 'Cancelled', 'Expired', 'Pending'],
      default: 'Pending'
    },
    date: { 
      type: Date, 
      required: true,
      default: Date.now 
    },
    time: {
      type: String,
      required: true,
      default: () => new Date().toTimeString().slice(0, 5),
      match: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/
    },
    validityDays: {
      type: Number,
      min: 1,
      default: 30
    }, 
    notes: String
  },

  // 2. consultation REFERENCE
  consultation: {
    type: Schema.Types.ObjectId,
    required: true,
    index: true
  },

  // 3. MEDICATION DETAILS - MODIFIÉ POUR SUPPORTER LES DEUX CAS
  medications: [{
    // CAS 1: Médicament de la base de données
    medication: {
      type: Schema.Types.ObjectId,
      ref: 'Medication',
      required: false  // ✅ Plus obligatoire maintenant
    },
    
    // CAS 2: Médicament libre (nouveau champ)
    customMedication: {
      name: String,           // Nom du médicament libre
      description: String     // Description optionnelle
    },
    
    dosage: {
      strength: String,       // "500mg"
      form: String,          // "tablet", "liquid", etc.
      frequency: String,     // "Twice daily"
      duration: String,      // "7 days"
      route: String,         // "Oral", "IV", etc.
      timing: String,        // "Morning and evening"
      asNeeded: Boolean,     // PRN medication
      instructions: String   // "Take with food"
    },
    quantity: {
      prescribed: Number,    // Total units prescribed
      dispensed: Number      // Actual units dispensed
    },
    refills: {
      allowed: Number,
      remaining: Number
    }
  }],

  // PDF Path
  pdfPath: String
}, {
  timestamps: true,
  toJSON: { virtuals: true }
});

// VALIDATION PERSONNALISÉE : Au moins un des deux doit être présent
PrescriptionSchema.pre('save', function(next) {
  for (let med of this.medications) {
    if (!med.medication && !med.customMedication?.name) {
      return next(new Error('Chaque médicament doit avoir soit une référence medication, soit un customMedication.name'));
    }
  }
  next();
});

module.exports = mongoose.model('Prescription', PrescriptionSchema);