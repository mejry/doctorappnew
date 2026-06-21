const { consumeEvents } = require('../../utils/rabbit');
const PrescriptionService = require('../../services/prescriptionService');
const logger = require('../../utils/logger');
const ConsultationCache = require('../../services/consultationCache'); 
const prescriptionService = require('../../services/prescriptionService');
//const prescriptionService = new PrescriptionService();

async function initPrescriptionConsumers() {
  try {

    await consumeEvents('prescription_consultation_queue', 'consultation.created', async (event) => {
      console.log('event', event.data);
      try {
        logger.info(`Received consultation event: ${event.eventType}`);
        
        // Ajouter la consultation au cache
        ConsultationCache.updateConsultation({
          consultationId: event.data.consultationId,
          patientId: event.data.patientId,
          patientName: event.data.patientName,
          patientEmail: event.data.patientEmail,
          status: event.data.status ,
          date: event.data.date,
          ttl: 86400000
        });

        // Créer une prescription vide
         prescription = await prescriptionService.handleNewConsultation(event.data);
        logger.info(`Created prescription for consultation ${event.data.consultationId}`);
      } catch (error) {
        logger.error(`Error processing consultation event: ${error.message}`);
        throw error;
      }
    });

    logger.info('Prescription consumers initialized');
  } catch (error) {
    logger.error(`Failed to initialize prescription consumers: ${error.message}`);
    throw error;
  }
}

module.exports = initPrescriptionConsumers;