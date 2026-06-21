from flask import Blueprint, request, jsonify
import logging
from services.prediction_service import PredictionService

logger = logging.getLogger(__name__)
prediction_bp = Blueprint('predictions', __name__)

@prediction_bp.route('/predict-medications', methods=['POST'])
def predict_medications():
    try:
        data = request.get_json()
        if not data:
            return jsonify({
                "success": False,
                "error": "Données JSON requises"
            }), 400
        
        auth_token = request.headers.get('Authorization', '').replace('Bearer ', '')
        
        # Mode 1: Avec patient_id
        if 'patient_id' in data:
            patient_id = data['patient_id']
            consultation_data = data.get('consultation_data', {})
            
            result = PredictionService.predict_medications(
                patient_id=patient_id,
                consultation_data=consultation_data,
                auth_token=auth_token
            )
        
        # Mode 2: Avec données complètes
        elif 'patient_data' in data:
            result = PredictionService.predict_medications(
                patient_data=data['patient_data']
            )
        
        else:
            return jsonify({
                "success": False,
                "error": "patient_id ou patient_data requis"
            }), 400
        
        status_code = 200 if result['success'] else 500
        return jsonify(result), status_code
        
    except Exception as e:
        logger.error(f"❌ Erreur endpoint: {e}")
        return jsonify({
            "success": False,
            "error": "Erreur interne du serveur"
        }), 500

@prediction_bp.route('/model-info', methods=['GET'])
def model_info():
    try:
        if not PredictionService.is_model_loaded():
            return jsonify({
                "success": False,
                "error": "Modèle non chargé"
            }), 503
        
        return jsonify({
            "success": True,
            "model_info": {
                "version": "1.0.0",
                "algorithm": "Random Forest with Binary Relevance",
                "total_medications": 10,  # Mode MOCK
                "features_count": 331,
                "accuracy": "92.2%",
                "status": "loaded",
                "mode": "MOCK" if PredictionService._model_manager.is_mock_mode else "REAL"
            }
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@prediction_bp.route('/predict-test', methods=['POST'])
def predict_test():
    """Endpoint de test avec données prédéfinies pour déclencher des prédictions"""
    test_data = {
        "patient_data": {
            "age": 65,  # Âge élevé pour déclencher hypertension
            "gender": "male",
            "medical_history": {
                "bloodGlucoseLevel": 180,  # Diabète
                "heartRate": 95,  # Élevé
                "bloodPressure": "160/100",  # Hypertension sévère
                "oxygenSaturation": 94,  # Bas
                "respiratoryRate": 22,  # Élevé
                "bodyTemperature": 37.5,  # Fièvre légère
                "weight": 95,  # Surpoids
                "height": 175,
                "chronicDiseases": ["hypertension", "diabetes"],
                "smokingStatus": "Ex-smoker",
                "alcoholConsumption": "Occasionally"
            },
            "consultation_data": {
                "symptoms": ["chest pain", "shortness of breath", "dizziness"],
                "diagnosis": ["hypertensive crisis", "diabetes type 2"]
            }
        }
    }
    
    result = PredictionService.predict_medications(
        patient_data=test_data['patient_data']
    )
    
    return jsonify({
        "test_mode": True,
        "test_data": test_data,
        "result": result
    })