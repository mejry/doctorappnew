const { publishEvent } = require('../../utils/rabbit');

const publishPatientCreated = async (patient) => {
   console.log('patient', patient.firstName),
  await publishEvent(
    'patient.created',
    `patient.${patient._id}`,
    {
      patientId: patient._id,
      name: `${patient.firstName} ${patient.lastName}`,
     
      email: patient.email,
      dob: patient.dob
    }
  );
};

const publishPatientDeleted = async (patientId) => {
  await publishEvent(
    'patient.deleted',
    `patient.${patientId}`,
    { patientId }
  );
};

module.exports = {
  publishPatientCreated,
  publishPatientDeleted
};