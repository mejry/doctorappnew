import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Services externes
    PATIENT_SERVICE_URL = os.getenv('PATIENT_SERVICE_URL', 'http://localhost:8002')
    CONSULTATION_SERVICE_URL = os.getenv('CONSULTATION_SERVICE_URL', 'http://localhost:8003')
    PRESCRIPTION_SERVICE_URL = os.getenv('PRESCRIPTION_SERVICE_URL', 'http://localhost:8004')
    
    # Token pour l'authentification inter-services
    INTERNAL_SERVICE_TOKEN = os.getenv('INTERNAL_SERVICE_TOKEN', 'ai_service_internal_token_123')
    
    # Modèle IA
    MODEL_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'models')
    MODEL_VERSION = "1.0.0"
    
    # Performance
    REQUEST_TIMEOUT = 10
    LOG_LEVEL = "INFO"
