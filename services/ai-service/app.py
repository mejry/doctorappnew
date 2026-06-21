from flask import Flask, jsonify
from flask_cors import CORS
import logging
from config.config import Config
from routes.predictions import prediction_bp
from services.prediction_service import PredictionService

def create_app():
    app = Flask(__name__)
    
    # Configuration CORS
    CORS(app, origins=['*'])  # Permettre tous les origins pour le dev
    
    # Configuration des logs
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Enregistrer les blueprints
    app.register_blueprint(prediction_bp, url_prefix='/api/ia')
    
    # Route de santé
    @app.route('/health', methods=['GET'])
    def health_check():
        return jsonify({
            "status": "healthy",
            "service": "AI Prediction Service",
            "version": "1.0.0",
            "model_loaded": PredictionService.is_model_loaded(),
            "mode": "MOCK" if PredictionService._model_manager and PredictionService._model_manager.is_mock_mode else "REAL"
        })
    
    return app

if __name__ == '__main__':
    app = create_app()
    
    # Initialiser le service au démarrage
    try:
        print("🔄 Initialisation du service IA...")
        PredictionService.initialize()
        print("✅ Service IA initialisé avec succès")
        
        # Vérifier le mode de fonctionnement
        if PredictionService._model_manager.is_mock_mode:
            print("🎭 MODE MOCK ACTIVÉ - Utilisation de prédictions simulées")
            print("📋 Pour utiliser le vrai modèle, placez ces fichiers dans ai-service/models/:")
            print("   - model.pkl (votre modèle entraîné)")
            print("   - medications.json (liste des médicaments)")
            print("   - columns.json (colonnes de features)")
        else:
            print("🤖 MODE RÉEL ACTIVÉ - Utilisation du modèle entraîné")
        
        print("🔗 API disponible sur: http://localhost:5000")
        print("📊 Endpoints:")
        print("   GET  /health")
        print("   GET  /api/ia/model-info") 
        print("   POST /api/ia/predict-medications")
        print("   POST /api/ia/predict-test")
    except Exception as e:
        print(f"❌ Erreur d'initialisation: {e}")
        exit(1)
    
    # Démarrer le serveur
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )