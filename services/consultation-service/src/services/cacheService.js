class PatientCache {
    static patients = new Map();
  
    static async updatePatient(patientData) {
      this.patients.set(patientData.patientId, patientData);
    }
  
    static async removePatient(patientId) {
      this.patients.delete(patientId);
    }
  
    static async getPatient(patientId) {
      return this.patients.get(patientId);
    }
  }
  
  module.exports = PatientCache;