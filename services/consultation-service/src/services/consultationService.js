const Consultation = require('../models/Consultation');
const PDFDocument = require('pdfkit');
const PatientCache = require('./cacheService');
const axios = require('axios');
const { 
  publishConsultationCreated,
  publishConsultationUpdated 
} = require('../events/publishers/consultationPublisher');

const fs = require('fs');

class ConsultationService {
  async createConsultation(data, authToken = null) {
    // 1. Vérifiez d'abord le cache
    let patient = await PatientCache.getPatient(data.patientId);
    
    // 2. Si absent, vérifiez via l'API patient-service
    if (!patient) {
      try {
        const headers = {};
        if (authToken) {
          headers.Authorization = authToken;
        }

        const response = await axios.get(
          `http://localhost:8002/api/patients/${data.patientId}`,
          { headers }
        );
        
        patient = response.data;
        await PatientCache.updatePatient({
          patientId: patient._id,
          name: `${patient.firstName} ${patient.lastName}`,
          email: patient.email
        });
      } catch (error) {
        console.error('Patient fetch error:', error.response?.data || error.message);
        throw new Error(`Patient verification failed: ${error.message}`);
      }
    }
  
    // 3. Créez la consultation
    const consultation = new Consultation(data);
    await consultation.save();
    await publishConsultationCreated(consultation, authToken);
    return consultation;
  }

  async getConsultationById(id) {
    return await Consultation.findById(id);
  }

  async getConsultationsByPatient(patientId) {
    return await Consultation.find({ patientId }).sort({ date: -1 });
  }

  async getAllConsultations(filter = {}) {
    return await Consultation.find(filter).sort({ date: -1 });
  }

  async updateConsultation(id, data) {
    return await Consultation.findByIdAndUpdate(id, data, { new: true });
  }

  async deleteConsultation(id) {
    const result = await Consultation.findByIdAndDelete(id);
    return !!result;
  }

  async searchConsultations(query) {
    return await Consultation.find({
      $or: [
        { type: { $regex: query, $options: 'i' } },
        { notes: { $regex: query, $options: 'i' } },
        { diagnosis: { $regex: query, $options: 'i' } }
      ]
    });
  }

  async filterConsultations(criteria) {
    const filter = {};
    
    if (criteria.patientId) filter.patientId = criteria.patientId;
    if (criteria.status) filter.status = criteria.status;
    if (criteria.type) filter.type = criteria.type;
    if (criteria.dateFrom || criteria.dateTo) {
      filter.date = {};
      if (criteria.dateFrom) filter.date.$gte = new Date(criteria.dateFrom);
      if (criteria.dateTo) filter.date.$lte = new Date(criteria.dateTo);
    }
    if (criteria.isEmergency !== undefined) {
      filter.isEmergency = criteria.isEmergency;
    }

    return this.getAllConsultations(filter);
  }

  async exportConsultationAsPDF(id) {
    const consultation = await this.getConsultationById(id);
    if (!consultation) {
      throw new Error('Consultation not found');
    }

    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument();
        const buffers = [];
        
        doc.on('data', buffers.push.bind(buffers));
        doc.on('end', () => {
          const pdfData = Buffer.concat(buffers);
          resolve(pdfData);
        });

        // En-tête du document
        doc.fontSize(20).text('Rapport de Consultation', { align: 'center' });
        doc.moveDown();

        // Informations patient
        doc.fontSize(14).text(`Patient: ${consultation.patientId}`);
        doc.text(`Date: ${consultation.date.toLocaleDateString()} ${consultation.time}`);
        doc.moveDown();

        // Détails consultation
        doc.fontSize(16).text('Détails:');
        doc.fontSize(12)
           .text(`Type: ${consultation.type}`)
           .text(`Statut: ${consultation.status}`)
           .text(`Durée: ${consultation.duration} minutes`)
           .text(`Urgence: ${consultation.isEmergency ? 'Oui' : 'Non'}`);
        doc.moveDown();

        // Symptômes et diagnostic
        doc.fontSize(14).text('Symptômes:');
        consultation.symptoms.forEach(symptom => doc.text(`- ${symptom}`));
        doc.moveDown();

        doc.fontSize(14).text('Diagnostic:');
        consultation.diagnosis.forEach(diag => doc.text(`- ${diag}`));
        doc.moveDown();

        // Notes
        if (consultation.notes) {
          doc.fontSize(14).text('Notes:');
          doc.text(consultation.notes);
        }

        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }
}

module.exports = new ConsultationService();