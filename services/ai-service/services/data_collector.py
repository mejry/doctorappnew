import requests
import logging
from typing import Dict, Any, Optional, List
from config.config import Config

logger = logging.getLogger(__name__)

class DataCollector:
    def __init__(self):
        self.timeout = Config.REQUEST_TIMEOUT
        self.patient_url = Config.PATIENT_SERVICE_URL
        self.consultation_url = Config.CONSULTATION_SERVICE_URL
        self.internal_token = Config.INTERNAL_SERVICE_TOKEN
    
    def get_patient_data(self, patient_id: str, auth_token: str = None) -> Optional[Dict[str, Any]]:
        try:
            # Utiliser les routes internes qui ne nécessitent pas d'auth
            url = f"{self.patient_url}/api/patients/internal/{patient_id}"
            response = requests.get(url, timeout=self.timeout)
            
            if response.status_code == 200:
                logger.info(f"✅ Données patient récupérées: {patient_id}")
                return response.json()
            else:
                logger.warning(f"⚠️ Patient non trouvé: {patient_id} - Status: {response.status_code}")
                return None
                
        except requests.RequestException as e:
            logger.error(f"❌ Erreur API patient: {e}")
            return None
    
    def get_medical_history(self, patient_id: str, auth_token: str = None) -> Dict[str, Any]:
        try:
            # Utiliser la route interne pour l'historique médical
            url = f"{self.patient_url}/api/patients/internal/{patient_id}/medical-history"
            response = requests.get(url, timeout=self.timeout)
            
            if response.status_code == 200:
                history = response.json()
                return history[0] if history else {}
            else:
                logger.warning(f"⚠️ Historique médical non trouvé pour patient: {patient_id}")
                return {}
                
        except requests.RequestException as e:
            logger.error(f"❌ Erreur API historique médical: {e}")
            return {}
    
    def get_consultation_data(self, consultation_id: str, auth_token: str = None) -> Dict[str, Any]:
        try:
            # Utiliser la route interne pour les consultations
            url = f"{self.consultation_url}/api/consultations/internal/{consultation_id}"
            response = requests.get(url, timeout=self.timeout)
            
            if response.status_code == 200:
                logger.info(f"✅ Consultation récupérée: {consultation_id}")
                return response.json()
            else:
                logger.warning(f"⚠️ Consultation non trouvée: {consultation_id} - Status: {response.status_code}")
                return {}
                
        except requests.RequestException as e:
            logger.error(f"❌ Erreur API consultation: {e}")
            return {}
