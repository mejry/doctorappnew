const Patient = require('../models/Patient');
const MedicalHistory = require('../models/MedicalHistory');
const { publishPatientCreated, publishPatientDeleted } = require('../events/publishers/patientPublisher'); 

class PatientService {
  async createPatient(data) {
    const patient = new Patient(data);
    
     await patient.save();
    await publishPatientCreated(patient); // Emit event
    return patient;

  }

  async getAllPatients() {
    return await Patient.find().sort({ createdAt: -1 });
  }

  async getPatientById(id) {
    return await Patient.findById(id);
  }

  async updatePatient(id, data) {
    return await Patient.findByIdAndUpdate(id, data, { new: true });
  }

  // ✅ CORRECTION: Méthode deletePatient corrigée
  async deletePatient(id) {
    try {
      console.log(`🗑️ Attempting to delete patient: ${id}`);
      
      // Vérifier que le patient existe
      const patient = await Patient.findById(id);
      if (!patient) {
        throw new Error('Patient not found');
      }

      // ✅ CORRECTION: Supprimer MEDICAL HISTORY en premier (pas Patient)
      const deletedHistories = await MedicalHistory.deleteMany({ patientId: id });
      console.log(`📋 Deleted ${deletedHistories.deletedCount} medical history records`);

      // Ensuite supprimer le patient
      const deletedPatient = await Patient.findByIdAndDelete(id);
      
      if (deletedPatient) {
        console.log(`✅ Patient ${id} deleted successfully`);
        await publishPatientDeleted(id);
        return deletedPatient;
      } else {
        throw new Error('Failed to delete patient');
      }
    } catch (error) {
      console.error(`❌ Error deleting patient ${id}:`, error);
      throw error;
    }
  }

  async addMedicalHistory(patientId, historyData) {
    const history = new MedicalHistory({ patientId, ...historyData });
    return await history.save();
  }

  async getMedicalHistoryByPatientId(patientId) {
    return await MedicalHistory.find({ patientId }).sort({ createdAt: -1 });
  }

  async updateMedicalHistory(id, historyData) {
    return await MedicalHistory.findByIdAndUpdate(id, historyData, { new: true });
  }

  async deleteMedicalHistory(id) {
    const result = await MedicalHistory.findByIdAndDelete(id);
    return !!result;
  }

  // Recherche de patients par nom ou email
  async searchPatients(query) {
    const { firstname, lastname, email } = query; // Changé de 'name' à 'firstname' et 'lastname'
    const searchQuery = {};
    
    if (firstname) {
      searchQuery.firstName = { $regex: firstname, $options: 'i' }; // Recherche exacte sur firstName
    }
    
    if (lastname) {
      searchQuery.lastName = { $regex: lastname, $options: 'i' }; // Recherche exacte sur lastName
    }
    
    if (email) {
      searchQuery.email = { $regex: email, $options: 'i' };
    }
    
    return await Patient.find(searchQuery);
  }
// patientService.js
async  syncAllPatients() {
  const patients = await Patient.find();
  patients.forEach(p => publishPatientCreated(p));
}

  async filterPatients(filters) {
    const { gender, dob, civilStatus } = filters;
    const filterQuery = {};
    
    if (gender) filterQuery.gender = gender;
    if (dob) filterQuery.dob = { $eq: new Date(dob) };
    if (civilStatus) filterQuery.civilStatus = civilStatus;
    
    return await Patient.find(filterQuery).sort({ createdAt: -1 });
  }

  // patientService.js
async getCurrentMonthPatientCount() {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  
  return await Patient.countDocuments({
    createdAt: {
      $gte: startOfMonth,
      $lte: now
    }
  });
}

// Recherche dans l'historique médical
async searchMedicalHistory(patientId, query) {
  const { vitals, date } = query;
  const searchQuery = { patientId };
  
  if (vitals) {
    searchQuery.$or = [
      { bloodPressure: { $regex: vitals, $options: 'i' } },
      { bodyTemperature: parseFloat(vitals) || undefined },
      { weight: parseFloat(vitals) || undefined }
    ].filter(Boolean);
  }
  
  if (date) {
    searchQuery.createdAt = {
      $gte: new Date(date),
      $lt: new Date(new Date(date).setDate(new Date(date).getDate() + 1))
    };
  }
  
  return await MedicalHistory.find(searchQuery).sort({ createdAt: -1 });
}

}

module.exports = new PatientService();