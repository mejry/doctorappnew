const mongoose = require('mongoose');

const MedicationSchema = new mongoose.Schema({
  // 1. IDENTIFICATION
  identification: {
    name: {
      type: String,
      required: true,
      index: true
    },
    brandNames: [String],
    genericName: {
      type: String,
      index: true
    },
    codes: {
      atc: String,                // ATC classification code
      national: String,           // National drug code
      internal: {                 // Internal pharmacy code
        type: String,
        unique: true
      }
    },
    isGeneric: Boolean,
    manufacturer: {
      name: String,
      country: String
    }
  },

pharmaceuticalProperties: {
  form: {
    type: String,
    enum: [
      'Tablet', 'Capsule', 'Solution', 'Injection', 
      'Cream', 'Suppository', 'Suspension', 'Aerosol',
      'Powder', 'Patch', 'Drops', 'Other'
    ],
    required: [true, 'Form is required'],
    default: 'Tablet'
  },
  route: {
    type: String,
    enum: [
      'Oral', 'Sublingual', 'Topical', 'IV', 
      'IM', 'SC', 'Rectal', 'Inhalation', 'Other'
    ],
    required: [true, 'Route is required'],
    default: 'Oral'
  },
  // ... autres champs
},

  // 3. DOSAGE & ADMINISTRATION
  dosage: {
    standard: {
      adult: {
        dose: String,
        frequency: String,
        maxDailyDose: String
      },
      pediatric: {
        byWeight: String,   // "10mg/kg/day"
        byAge: [{
          ageRange: String, // "2-6 years"
          dose: String
        }]
      }
    },
    specialPopulations: {
      elderly: String,
      renalImpairment: String,
      hepaticImpairment: String
    },
    administrationInstructions: String
  },

  // 4. SAFETY INFORMATION
  safety: {
    sideEffects: {
      common: [String],
      serious: [String],
      frequencyBased: [{
        frequency: {
          type: String,
          enum: ['Very common', 'Common', 'Uncommon', 'Rare']
        },
        effect: String,
        management: String
      }]
    },
    warnings: [String],
    contraindications: [String],
    blackBoxWarnings: [String],
    pregnancy: {
      category: {
        type: String,
        enum: ['A', 'B', 'C', 'D', 'X']
      },
      riskDescription: String
    },
    lactation: {
      risk: {
        type: String,
        enum: ['Safe', 'Caution', 'Contraindicated', 'Unknown']
      },
      advice: String
    }
  },

  // 5. STOCK & AVAILABILITY
  inventory: {
    currentStock: Number,
    unit: String,           // "tablets", "vials", etc.
    threshold: Number,      // Reorder threshold
    status: {
      type: String,
      enum: [
        'In Stock', 'Low Stock', 
        'Out of Stock', 'Discontinued'
      ],
      default: 'In Stock'
    },
    lastRestock: Date,
    expiration: Date
  },

  // 6. CLINICAL INFORMATION
  clinical: {
    therapeuticClass: String,
    mechanismOfAction: String,
    indications: [String],
    interactions: [{
      type: {
        type: String,
        enum: ['Drug', 'Food', 'Herbal', 'Other']
      },
      substance: String,
      effect: String
    }],
    monitoring: [String]    // e.g., "Liver function tests"
  },

  // 7. METADATA
  metadata: {
    lastUpdated: {
      type: Date,
      default: Date.now
    },
    sources: [String],     // References
    notes: String
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

module.exports = mongoose.model('Medication', MedicationSchema);