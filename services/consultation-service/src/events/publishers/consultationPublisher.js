const { publishEvent } = require('../../utils/rabbit');
const PatientCache = require('../../services/cacheService');
const axios = require('axios');

exports.publishConsultationCreated = async (consultation, authToken = null) => {
  try {
    let patientName = 'Unknown Patient';
    let patientEmail = 'unknown@email.com';

    // Try to get patient info from cache first
    const cachedPatient = await PatientCache.getPatient(consultation.patientId);
    
    if (cachedPatient) {
      patientName = cachedPatient.name;
      patientEmail = cachedPatient.email;
    } else {
      // If not in cache, try to fetch from patient service
      try {
        const headers = {};
        if (authToken) {
          headers.Authorization = authToken;
        }

        const response = await axios.get(
          `http://localhost:8002/api/patients/${consultation.patientId}`,
          { headers }
        );
        
        console.log('Response from patient-service:', response.data);
        patientName = `${response.data.firstName} ${response.data.lastName}`;
        patientEmail = response.data.email;
        
        // Update cache for future use
        await PatientCache.updatePatient({
          patientId: consultation.patientId,
          name: patientName,
          email: patientEmail
        });
      } catch (error) {
        console.warn('Failed to fetch patient details for event:', error.message);
        // Continue with default values
      }
    }

    await publishEvent(
      'consultation.created',
      `consultation.${consultation._id}`,
      {
        consultationId: consultation._id,
        patientId: consultation.patientId,
        patientName: patientName,
        patientEmail: patientEmail,
        status: consultation.status,
        date: consultation.date,
        type: consultation.type,
      }
    );

    console.log(`Published consultation.created event for ${consultation._id}`);
  } catch (error) {
    console.error(`Failed to publish consultation event: ${error.message}`);
    throw error;
  }
};

exports.publishConsultationUpdated = async (consultation) => {
  await publishEvent(
    'consultation.updated',
    `consultation.${consultation.patientId}`,
    {
      consultationId: consultation._id,
      changes: consultation.changes
    }
  );
};