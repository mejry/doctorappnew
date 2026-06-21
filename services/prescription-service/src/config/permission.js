// config/permission.js
module.exports = {
  // Permissions prescriptions
  PRESCRIPTION: {
    VIEW: 'view_prescription',
    CREATE: 'create_prescription',
    UPDATE: 'update_prescription',
    DELETE: 'delete_prescription',
    SEARCH: 'search_prescription',
    EXPORT: 'export_prescription_pdf',
    SEND_EMAIL: 'send_prescription_email'
  },
  
  // Permissions filtres et recherches avancées
  PRESCRIPTION_FILTERS: {
    FILTER_BY_PATIENT: 'filter_prescription_by_patient',
    FILTER_BY_DATE: 'filter_prescription_by_date',
    FILTER_BY_STATUS: 'filter_prescription_by_status',
    FILTER_BY_DOCTOR: 'filter_prescription_by_doctor'
  },

  // Permissions médicaments
  MEDICATION: {
    VIEW: 'view_medication',
    CREATE: 'create_medication',
    UPDATE: 'update_medication',
    DELETE: 'delete_medication',
    SEARCH: 'view_medication'
  }
};