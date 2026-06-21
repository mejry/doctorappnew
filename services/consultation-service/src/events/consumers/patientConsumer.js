const { consumeEvents } = require('../../utils/rabbit');
const PatientCache = require('../../services/cacheService');

// Écoute les événements patients
exports.startPatientConsumer = () => {
  consumeEvents('consultation_patient_queue', 'patient.*', async (event) => {
    switch (event.eventType) {
      case 'patient.created':
      case 'patient.updated':
        await PatientCache.updatePatient(event.data);
        break;
      case 'patient.deleted':
        await PatientCache.removePatient(event.data.patientId);
        break;
    }
  });
};