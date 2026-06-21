const { publishEvent } = require('../../utils/rabbit');
const logger = require('../../utils/logger');

async function publishPrescriptionCreated(prescription) {
  try {
    await publishEvent(
      'prescription.created',
      `prescription.${prescription._id}`,
      {
        prescriptionId: prescription._id,
        consultationId: prescription.consultation,
        status: prescription.status
      }
    );
    logger.info(`Published prescription.created event for ${prescription._id}`);
  } catch (error) {
    logger.error(`Failed to publish prescription event: ${error.message}`);
    throw error;
  }
}

module.exports = {
  publishPrescriptionCreated
};