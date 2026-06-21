module.exports = {
  // Permissions patients
  PATIENT: {
    VIEW: 'view_patient',
    CREATE: 'create_patient',
    UPDATE: 'update_patient',
    DELETE: 'delete_patient',
    SEARCH: 'search_patient',
    EXPORT: 'export_patient_data'
  },
  
  // Permissions historique médical

  
  // Permissions statistiques
  STATS: {
    VIEW: 'view_patient_stats',
    EXPORT: 'export_patient_stats'
  },
  
  // Permissions système
  SYSTEM: {
    SYNC: 'sync_patient_data',
    BULK_OPERATIONS: 'bulk_patient_operations'
  }
};