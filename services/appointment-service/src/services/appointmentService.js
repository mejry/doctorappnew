// appointment-service/src/services/appointmentService.js
const Appointment = require("../models/Appointment");
const EmailService = require("./emailService");
const rabbitmq = require("../config/rabbitmq");
const logger = require("../config/logger");
const config = require("../config/config");

/**
 * Check for scheduling conflicts
 * @param {Object} params - Parameters for conflict check
 * @returns {Object} - Conflict check result
 */
async function checkForConflicts({
  doctorId,
  date,
  time,
  duration,
  excludeId = null,
}) {
  try {
    const appointmentDate = new Date(date);
    const startTime = convertTimeToMinutes(time);
    const endTime = startTime + duration;

    // Set date range for the day
    const startOfDay = new Date(appointmentDate);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(appointmentDate);
    endOfDay.setHours(23, 59, 59, 999);

    // Find appointments for the doctor on that day
    const query = {
      doctorId,
      date: { $gte: startOfDay, $lte: endOfDay },
      status: { $nin: ["Cancelled", "No-show"] },
    };

    // Exclude current appointment if updating
    if (excludeId) {
      query._id = { $ne: excludeId };
    }

    const appointments = await Appointment.find(query);

    // Check for time conflicts
    for (const appointment of appointments) {
      const existingStartTime = convertTimeToMinutes(appointment.time);
      const existingEndTime = existingStartTime + appointment.duration;

      // Check for overlap
      if (
        (startTime >= existingStartTime && startTime < existingEndTime) ||
        (endTime > existingStartTime && endTime <= existingEndTime) ||
        (startTime <= existingStartTime && endTime >= existingEndTime)
      ) {
        return {
          hasConflict: true,
          conflictingAppointment: appointment,
        };
      }
    }

    return { hasConflict: false };
  } catch (error) {
    logger.error("Error checking for conflicts:", error);
    throw error;
  }
}

/**
 * Convert time string (HH:MM) to minutes since midnight
 * @param {string} time - Time in HH:MM format
 * @returns {number} - Minutes since midnight
 */
function convertTimeToMinutes(time) {
  const [hours, minutes] = time.split(":").map(Number);
  return hours * 60 + minutes;
}

/**
 * Create a new appointment
 * @param {Object} appointmentData - Appointment data
 * @returns {Object} - Created appointment
 */
async function createAppointment(appointmentData) {
  try {
    logger.debug("Creating appointment with data:", appointmentData);

    // Validate required fields
    const requiredFields = [
      "patientName",
      "doctorId",
      "doctorName",
      "date",
      "time",
      "type",
    ];
    for (const field of requiredFields) {
      if (!appointmentData[field]) {
        throw new Error(`${field} is required`);
      }
    }

    // Check for conflicts
    const { hasConflict, conflictingAppointment } = await checkForConflicts({
      doctorId: appointmentData.doctorId,
      date: appointmentData.date,
      time: appointmentData.time,
      duration: appointmentData.duration || 30,
    });

    if (hasConflict) {
      logger.warn("Scheduling conflict detected:", conflictingAppointment);
      return {
        success: false,
        message: "Scheduling conflict detected",
        conflict: true,
        conflictingAppointment,
      };
    }

    // Create appointment
    const appointment = new Appointment(appointmentData);
    await appointment.save();

    logger.info(`Appointment created successfully: ID ${appointment._id}`);

    // Publish to RabbitMQ - Use try/catch to handle potential errors
    try {
      await rabbitmq.publish(
        config.rabbitmq.queues.appointmentCreated,
        appointment.toObject(),
      );
      logger.info("Published appointment created event to RabbitMQ");
    } catch (mqError) {
      logger.warn("Failed to publish to RabbitMQ:", mqError.message);
      // Continue anyway - don't let RabbitMQ issues prevent appointment creation
    }

    // Send email notification
    if (appointment.patientContact?.email) {
      try {
        await EmailService.sendAppointmentCreatedEmail(appointment);
      } catch (emailError) {
        logger.warn("Failed to send email notification:", emailError.message);
      }
    }

    return {
      success: true,
      appointment: appointment.toObject(),
    };
  } catch (error) {
    logger.error("Error creating appointment:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Update an existing appointment
 * @param {string} id - Appointment ID
 * @param {Object} updateData - Data to update
 * @returns {Object} - Updated appointment
 */
async function updateAppointment(id, updateData) {
  try {
    logger.debug(`Updating appointment ${id} with data:`, updateData);

    // Find appointment
    const appointment = await Appointment.findById(id);
    if (!appointment) {
      return {
        success: false,
        message: "Appointment not found",
      };
    }

    // Check for conflicts if date/time changed
    if (updateData.date || updateData.time) {
      const { hasConflict, conflictingAppointment } = await checkForConflicts({
        doctorId: updateData.doctorId || appointment.doctorId,
        date: updateData.date || appointment.date,
        time: updateData.time || appointment.time,
        duration: updateData.duration || appointment.duration,
        excludeId: id,
      });

      if (hasConflict) {
        logger.warn(
          "Scheduling conflict detected during update:",
          conflictingAppointment,
        );
        return {
          success: false,
          message: "Scheduling conflict detected",
          conflict: true,
          conflictingAppointment,
        };
      }
    }

    // Handle cancellation
    if (updateData.status === "Cancelled") {
      if (!updateData.cancellationReason) {
        return {
          success: false,
          message: "Cancellation reason is required",
        };
      }
      updateData.cancellationDate = new Date();
    }

    // Update appointment
    const updatedAppointment = await Appointment.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true, runValidators: true },
    );

    logger.info(
      `Appointment updated successfully: ID ${updatedAppointment._id}`,
    );

    // Publish event based on update type with error handling
    try {
      if (updateData.status === "Cancelled") {
        await rabbitmq.publish(
          config.rabbitmq.queues.appointmentCancelled,
          updatedAppointment.toObject(),
        );

        if (updatedAppointment.patientContact?.email) {
          try {
            await EmailService.sendAppointmentCancelledEmail(
              updatedAppointment,
            );
          } catch (emailError) {
            logger.warn(
              "Failed to send cancellation email:",
              emailError.message,
            );
          }
        }
      } else {
        await rabbitmq.publish(
          config.rabbitmq.queues.appointmentUpdated,
          updatedAppointment.toObject(),
        );

        if (updatedAppointment.patientContact?.email) {
          try {
            await EmailService.sendAppointmentUpdatedEmail(updatedAppointment);
          } catch (emailError) {
            logger.warn("Failed to send update email:", emailError.message);
          }
        }
      }
    } catch (mqError) {
      logger.warn("Failed to publish to RabbitMQ:", mqError.message);
      // Continue anyway
    }

    return {
      success: true,
      appointment: updatedAppointment.toObject(),
    };
  } catch (error) {
    logger.error("Error updating appointment:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Search and filter appointments
 * @param {Object} filters - Search filters
 * @returns {Object} - Search results
 */
async function getAppointments(filters = {}) {
  try {
    logger.debug("Getting appointments with filters:", filters);

    const {
      doctorId,
      patientName,
      date,
      startDate,
      endDate,
      status,
      type,
      limit = 50,
      skip = 0,
      sort = { date: 1, time: 1 },
    } = filters;

    // Build query
    const query = {};

    if (doctorId) query.doctorId = doctorId;
    if (status) query.status = status;
    if (type) query.type = type;

    // Text search for patient name
    if (patientName) {
      query.$text = { $search: patientName };
    }

    // Date filtering
    if (date) {
      const searchDate = new Date(date);
      const startOfDay = new Date(searchDate);
      startOfDay.setHours(0, 0, 0, 0);

      const endOfDay = new Date(searchDate);
      endOfDay.setHours(23, 59, 59, 999);

      query.date = { $gte: startOfDay, $lte: endOfDay };
    } else if (startDate && endDate) {
      query.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    // Execute query
    const appointments = await Appointment.find(query)
      .sort(sort)
      .limit(Number(limit))
      .skip(Number(skip));

    const total = await Appointment.countDocuments(query);

    logger.info(`Found ${total} appointments matching query`);

    return {
      success: true,
      total,
      limit: Number(limit),
      skip: Number(skip),
      appointments: appointments.map((a) => a.toObject()),
    };
  } catch (error) {
    logger.error("Error fetching appointments:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Get appointment by ID
 * @param {string} id - Appointment ID
 * @returns {Object} - Appointment details
 */
async function getAppointmentById(id) {
  try {
    logger.debug(`Getting appointment by ID: ${id}`);

    const appointment = await Appointment.findById(id);

    if (!appointment) {
      return {
        success: false,
        message: "Appointment not found",
      };
    }

    logger.info(`Found appointment: ${id}`);

    return {
      success: true,
      appointment: appointment.toObject(),
    };
  } catch (error) {
    logger.error("Error fetching appointment by ID:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Get today's appointments for waiting room
 * @param {string} doctorId - Optional doctor ID to filter
 * @returns {Object} - Today's appointments
 */
async function getTodayAppointments(doctorId) {
  try {
    logger.debug(
      `Getting today's appointments${doctorId ? ` for doctor ${doctorId}` : ""}`,
    );

    const today = new Date();
    const startOfDay = new Date(today);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59, 999);

    const query = {
      date: { $gte: startOfDay, $lte: endOfDay },
      status: { $nin: ["Cancelled"] },
    };

    if (doctorId) {
      query.doctorId = doctorId;
    }

    const appointments = await Appointment.find(query).sort({ time: 1 });

    logger.info(`Found ${appointments.length} appointments for today`);

    return {
      success: true,
      appointments: appointments.map((a) => a.toObject()),
    };
  } catch (error) {
    logger.error("Error fetching today appointments:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Update appointment status based on waiting room updates
 * @param {Object} data - Status update data
 * @returns {Object} - Update result
 */
async function handleWaitingRoomUpdate(data) {
  try {
    const { appointmentId, status, notes, userId } = data;

    logger.debug(
      `Handling waiting room update for appointment ${appointmentId} - status: ${status}`,
    );

    // Find appointment
    const appointment = await Appointment.findById(appointmentId);
    if (!appointment) {
      logger.warn(
        `Waiting room update for non-existent appointment: ${appointmentId}`,
      );
      return {
        success: false,
        message: "Appointment not found",
      };
    }

    // Update status
    const oldStatus = appointment.status;
    appointment.status = status;

    if (notes) {
      appointment.notes = appointment.notes
        ? `${appointment.notes}\n${notes}`
        : notes;
    }

    // Set updatedBy if userId provided
    if (userId) {
      appointment.updatedBy = userId;
    }

    await appointment.save();

    logger.info(
      `Updated appointment ${appointmentId} status from ${oldStatus} to ${status}`,
    );

    return {
      success: true,
      appointment: appointment.toObject(),
    };
  } catch (error) {
    logger.error("Error handling waiting room update:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Schedule appointment reminders for the next day
 * @returns {Object} - Reminder results
 */
async function scheduleReminders() {
  try {
    logger.debug("Scheduling appointment reminders for tomorrow");

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);

    const startOfDay = new Date(tomorrow);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(tomorrow);
    endOfDay.setHours(23, 59, 59, 999);

    // Find all scheduled appointments for tomorrow
    const appointments = await Appointment.find({
      date: { $gte: startOfDay, $lte: endOfDay },
      status: "Scheduled",
      reminderSent: false,
    });

    let successCount = 0;

    for (const appointment of appointments) {
      if (appointment.patientContact?.email) {
        try {
          await EmailService.sendAppointmentReminderEmail(appointment);

          // Mark reminder as sent
          appointment.reminderSent = true;
          await appointment.save();

          successCount++;
        } catch (emailError) {
          logger.warn(
            `Failed to send reminder for appointment ${appointment._id}:`,
            emailError.message,
          );
        }
      }
    }

    logger.info(`Sent ${successCount} appointment reminders for tomorrow`);

    return {
      success: true,
      total: appointments.length,
      sent: successCount,
    };
  } catch (error) {
    logger.error("Error scheduling reminders:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}
/**
 * Get total appointment count for a doctor in a specific month
 * @param {string} doctorId - Doctor ID
 * @param {number} year - Year (e.g., 2024)
 * @param {number} month - Month (1-12)
 * @returns {Object} - Total appointment count
 */
async function getDoctorMonthlyAppointmentCount(doctorId, year, month) {
  try {
    logger.debug(
      `Getting appointment count for doctor ${doctorId} for ${year}-${month}`,
    );

    // Validate inputs
    if (!doctorId || !year || !month) {
      return {
        success: false,
        message: "Doctor ID, year, and month are required",
      };
    }

    if (month < 1 || month > 12) {
      return {
        success: false,
        message: "Month must be between 1 and 12",
      };
    }

    // Create date range for the specified month
    const startOfMonth = new Date(year, month - 1, 1); // 1st day of month
    const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999); // Last day of month

    // Count appointments for the doctor in this month
    const appointmentCount = await Appointment.countDocuments({
      doctorId: doctorId,
      date: {
        $gte: startOfMonth,
        $lte: endOfMonth,
      },
      status: { $nin: ["Cancelled", "No-show"] }, // Exclude cancelled and no-show
    });

    logger.info(
      `Doctor ${doctorId} has ${appointmentCount} appointments in ${year}-${month}`,
    );

    return {
      success: true,
      doctorId,
      year,
      month,
      monthName: new Date(year, month - 1).toLocaleDateString("en-US", {
        month: "long",
      }),
      totalAppointments: appointmentCount,
    };
  } catch (error) {
    logger.error("Error getting monthly appointment count:", error);
    return {
      success: false,
      message: error.message,
    };
  }
}

/**
 * Get current month appointment count for a doctor
 * @param {string} doctorId - Doctor ID
 * @returns {Object} - Current month appointment count
 */
async function getDoctorCurrentMonthAppointmentCount(doctorId) {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1; // getMonth() returns 0-11, we need 1-12

  return await getDoctorMonthlyAppointmentCount(doctorId, year, month);
}
module.exports = {
  createAppointment,
  updateAppointment,
  getAppointments,
  getAppointmentById,
  getTodayAppointments,
  handleWaitingRoomUpdate,
  scheduleReminders,
  getDoctorMonthlyAppointmentCount, // ← Add this
  getDoctorCurrentMonthAppointmentCount,
};
