const Medication = require('../models/Medication');
const logger = require('../utils/logger');

class MedicationService {
  async createMedication(data) {
    const medication = new Medication(data);
    return await medication.save();
  }

  async getMedicationById(id) {
    return await Medication.findById(id);
  }
  async getAllMedications(filter = {}) {
    const medications = await Medication.find(filter)
      .sort({ 'identification.name': 1 })
      .lean()
      .then(meds => meds.map(({ _id, ...rest }) => ({ 
        id: _id, 
        ...rest 
      })));
      
    return medications;
  }

  async updateMedication(id, data) {
    return await Medication.findByIdAndUpdate(id, data, { 
      new: true,
      runValidators: true 
    });
  }

  async deleteMedication(id) {
    const result = await Medication.findByIdAndDelete(id);
    return !!result;
  }

  async searchMedications(query) {
    return await Medication.find({
      $or: [
        { 'identification.name': { $regex: query, $options: 'i' } },
        { 'identification.genericName': { $regex: query, $options: 'i' } },
        { 'clinical.indications': { $regex: query, $options: 'i' } }
      ]
    }).lean().then(meds => meds.map(med => ({ id: med._id, ...med })));
  }
}

module.exports = new MedicationService();