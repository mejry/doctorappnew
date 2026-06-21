// models/MedicalHistory.js - VERSION CORRIGÉE POUR VOTRE MODÈLE IA
const mongoose = require('mongoose');

const MedicalHistorySchema = new mongoose.Schema({
  patientId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Patient', 
    required: true 
  },
  bloodGlucoseLevel: { type: Number },
  heartRate: { type: Number },
  oxygenSaturation: { type: Number },
  bloodPressure: { 
    type: mongoose.Schema.Types.Mixed, // ✅ CORRECTION: Accepter Number ou String
    validate: {
      validator: function(value) {
        if (value === null || value === undefined) return true;
        // Accepter les nombres (comme 118) ou les strings (comme "120/80")
        if (typeof value === 'number') return value > 0;
        if (typeof value === 'string') return /^\d+\/\d+$/.test(value);
        return false;
      },
      message: 'Blood pressure must be a number or format like "120/80"'
    }
  },
  respiratoryRate: { type: Number },
  bodyTemperature: { type: Number }, // In Celsius
  weight: { type: Number }, // In kg
  height: { type: Number }, // In cm
  
  // ✅ CORRECTION: Accepter String ou Array pour compatibilité modèle IA
  chronicDiseases: { 
    type: mongoose.Schema.Types.Mixed,
    validate: {
      validator: function(value) {
        if (value === null || value === undefined) return true;
        if (Array.isArray(value)) return true;
        if (typeof value === 'string') return true;
        return false;
      }
    },
    set: function(value) {
      // Convertir automatiquement string en array si nécessaire
      if (typeof value === 'string') {
        if (value === 'None' || value === '') return [];
        return value.includes(',') ? value.split(',').map(s => s.trim()) : [value];
      }
      return value;
    }
  },
  
  allergies: { 
    type: mongoose.Schema.Types.Mixed,
    validate: {
      validator: function(value) {
        if (value === null || value === undefined) return true;
        if (Array.isArray(value)) return true;
        if (typeof value === 'string') return true;
        return false;
      }
    },
    set: function(value) {
      // Convertir automatiquement string en array si nécessaire
      if (typeof value === 'string') {
        if (value === 'None' || value === '') return [];
        return value.includes(',') ? value.split(',').map(s => s.trim()) : [value];
      }
      return value;
    }
  },
  
  smokingStatus: { 
    type: String, 
    enum: ['Non-smoker', 'Ex-smoker', 'Smoker', 'Former smoker'] // ✅ AJOUT: Former smoker
  },
  
  alcoholConsumption: { 
    type: String, 
    enum: ['Never', 'Occasionally', 'Regularly', 'No'] // ✅ AJOUT: No
  },
  
  currentMedications: [{ 
    name: String,
    dosage: String,
    frequency: String 
  }]
}, { timestamps: true });

// ✅ NOUVEAU: Middleware pour nettoyer les données avant sauvegarde
MedicalHistorySchema.pre('save', function(next) {
  // Convertir bloodPressure number en string si nécessaire pour l'affichage
  if (typeof this.bloodPressure === 'number') {
    // Garder le nombre tel quel - votre modèle IA utilise des nombres
    // Pas de conversion nécessaire
  }
  
  // S'assurer que les arrays vides sont corrects
  if (!this.chronicDiseases) this.chronicDiseases = [];
  if (!this.allergies) this.allergies = [];
  if (!this.currentMedications) this.currentMedications = [];
  
  next();
});

module.exports = mongoose.model('MedicalHistory', MedicalHistorySchema);