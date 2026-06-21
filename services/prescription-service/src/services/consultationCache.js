const axios = require('axios');
const logger = require('../utils/logger');

class ConsultationCache {
  static consultations = new Map();

  static updateConsultation(consultationData) {
    if (consultationData?.consultationId) {
      ConsultationCache.consultations.set(
        consultationData.consultationId,
        consultationData
      );
      console.log(`✅ Consultation mise en cache: ${consultationData.consultationId}`);
    }
  }

  // ✅ MÉTHODE CORRIGÉE: Avec fallback API si pas en cache
  static async getConsultation(consultationId) {
    console.log(`🔍 Recherche consultation: ${consultationId}`);
    
    // 1. Vérifier d'abord le cache
    const cachedConsultation = this.consultations.get(consultationId);
    if (cachedConsultation) {
      console.log(`✅ Consultation trouvée en cache: ${consultationId}`);
      return cachedConsultation;
    }

    // 2. Si pas en cache, récupérer via API
    console.log(`⚠️ Consultation non trouvée en cache, appel API: ${consultationId}`);
    try {
      const response = await axios.get(
        `http://localhost:8003/api/consultations/internal/${consultationId}`, 
        { timeout: 10000 }
      );
      
      const consultationData = response.data;
      
      // 3. Mettre en cache pour la prochaine fois
      if (consultationData) {
        this.consultations.set(consultationId, {
          consultationId: consultationId,
          ...consultationData
        });
        console.log(`✅ Consultation récupérée via API et mise en cache: ${consultationId}`);
        return consultationData;
      }
    } catch (error) {
      console.error(`❌ Erreur API consultation ${consultationId}:`, error.message);
    }

    // 4. Aucune consultation trouvée
    console.error(`❌ Consultation non trouvée: ${consultationId}`);
    return null;
  }

  static getConsultationById(consultationId) {
    // Pour compatibilité, utiliser la même logique
    return this.getConsultation(consultationId);
  }

  static removeConsultation(consultationId) {
    const removed = ConsultationCache.consultations.delete(consultationId);
    if (removed) {
      console.log(`🗑️ Consultation supprimée du cache: ${consultationId}`);
    }
  }

  static clearCache() {
    const size = ConsultationCache.consultations.size;
    ConsultationCache.consultations.clear();
    console.log(`🧹 Cache nettoyé: ${size} consultations supprimées`);
  }

  // ✅ NOUVELLE MÉTHODE: Pré-charger les consultations actives
  static async preloadActiveConsultations() {
    try {
      console.log('🔄 Pré-chargement des consultations actives...');
      
      const response = await axios.get(
        'http://localhost:8003/api/consultations/internal/active',
        { timeout: 15000 }
      );
      
      const consultations = response.data;
      
      if (Array.isArray(consultations)) {
        consultations.forEach(consultation => {
          this.consultations.set(consultation._id || consultation.id, {
            consultationId: consultation._id || consultation.id,
            ...consultation
          });
        });
        
        console.log(`✅ ${consultations.length} consultations pré-chargées en cache`);
      }
    } catch (error) {
      console.warn(`⚠️ Impossible de pré-charger les consultations: ${error.message}`);
    }
  }

  // ✅ NOUVELLE MÉTHODE: Statistiques du cache
  static getCacheStats() {
    return {
      size: this.consultations.size,
      consultationIds: Array.from(this.consultations.keys())
    };
  }
}

module.exports = ConsultationCache;