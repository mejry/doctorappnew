import logging
from typing import Dict, Any, List
from models.model_manager import ModelManager
from services.data_collector import DataCollector
from preprocessing.feature_engineer import FeatureEngineer
from config.config import Config
import time

logger = logging.getLogger(__name__)


class PredictionService:
    _instance = None
    _model_manager = None
    _data_collector = None
    _feature_engineer = None
    _initialized = False

    @classmethod
    def initialize(cls):
        if cls._initialized:
            return

        try:
            cls._model_manager = ModelManager(Config.MODEL_PATH)
            if not cls._model_manager.load_model():
                raise Exception("Impossible de charger le modèle")

            cls._data_collector = DataCollector()
            cls._feature_engineer = FeatureEngineer()

            cls._initialized = True
            logger.info("✅ PredictionService initialisé")

        except Exception as e:
            logger.error(f"❌ Erreur initialisation: {e}")
            raise

    @classmethod
    def predict_medications(
        cls,
        patient_id: str = None,
        consultation_data: Dict[str, Any] = None,
        patient_data: Dict[str, Any] = None,
        auth_token: str = None,
    ) -> Dict[str, Any]:

        if not cls._initialized:
            raise Exception("Service non initialisé")

        start_time = time.time()

        try:
            consultation_data = consultation_data or {}

            if patient_id:
                logger.info(f"🔍 Collecte des données pour patient: {patient_id}")

                patient_info = cls._data_collector.get_patient_data(
                    patient_id, auth_token
                )

                if not patient_info:
                    raise ValueError(f"Patient non trouvé: {patient_id}")

                medical_history = cls._data_collector.get_medical_history(
                    patient_id, auth_token
                )

                if "age" not in patient_info and "dob" in patient_info:
                    from datetime import datetime

                    dob = datetime.strptime(patient_info["dob"][:10], "%Y-%m-%d")
                    patient_info["age"] = (datetime.now() - dob).days // 365

            elif patient_data:
                logger.info("📋 Utilisation des données directes")
                patient_info = patient_data
                medical_history = patient_data.get("medical_history", {})
                consultation_data = patient_data.get(
                    "consultation_data", consultation_data
                )

            else:
                raise ValueError("patient_id ou patient_data requis")

            logger.info("⚙️ Préparation des features")
            features = cls._feature_engineer.prepare_patient_features(
                patient_info, medical_history, consultation_data
            )

            logger.info("🧠 Prédiction en cours")
            prediction_result = cls._model_manager.predict(features)

            enriched_predictions = cls._enrich_predictions(
                prediction_result.get("predictions", []),
                patient_info,
                medical_history,
                consultation_data,
            )

            processing_time = int((time.time() - start_time) * 1000)

            response = {
                "success": True,
                "patient_id": patient_id or "manual",
                "predictions": enriched_predictions,
                "total_medications": len(enriched_predictions),
                "model_version": prediction_result.get("model_version", "unknown"),
                "processing_time": f"{processing_time}ms",
                "timestamp": int(time.time()),
                "mock_mode": prediction_result.get("mock_mode", False),
                "engine": "REAL_ML_MODEL"
                if not prediction_result.get("mock_mode", False)
                else "MOCK_ENGINE",
                "disclaimer": "AI suggestions are decision-support only. Doctor validation is required before prescription.",
            }

            logger.info(
                f"✅ Prédiction réussie: {len(enriched_predictions)} médicaments"
            )
            return response

        except Exception as e:
            logger.error(f"❌ Erreur prédiction: {e}")
            return {
                "success": False,
                "error": str(e),
                "patient_id": patient_id or "manual",
                "processing_time": f"{int((time.time() - start_time) * 1000)}ms",
            }

    @classmethod
    def _enrich_predictions(
        cls,
        predictions: List[Dict[str, Any]],
        patient_info: Dict[str, Any],
        medical_history: Dict[str, Any],
        consultation_data: Dict[str, Any],
    ) -> List[Dict[str, Any]]:

        enriched = []

        symptoms = [str(s).lower() for s in consultation_data.get("symptoms", [])]
        diagnosis = [str(d).lower() for d in consultation_data.get("diagnosis", [])]
        chronic = [
            str(c).lower() for c in medical_history.get("chronicDiseases", [])
        ]

        bp = medical_history.get("bloodPressure", "120/80")
        systolic = 120
        diastolic = 80

        if isinstance(bp, str) and "/" in bp:
            try:
                systolic, diastolic = bp.split("/")
                systolic = float(systolic)
                diastolic = float(diastolic)
            except Exception:
                systolic = 120
                diastolic = 80

        glucose = float(medical_history.get("bloodGlucoseLevel", 100))
        temperature = float(medical_history.get("bodyTemperature", 37))
        oxygen = float(medical_history.get("oxygenSaturation", 98))

        for pred in predictions:
            medication = pred.get("medication", "").lower()
            reasons = []
            warnings = []

            if medication == "paracetamol":
                if temperature >= 38:
                    reasons.append("High body temperature / fever detected")
                if "fever" in symptoms:
                    reasons.append("Fever symptom reported")
                if "headache" in symptoms:
                    reasons.append("Headache symptom reported")
                if "flu" in diagnosis or "cold" in diagnosis:
                    reasons.append("Flu/cold diagnosis context")

            elif medication == "amlodipine":
                if systolic >= 140 or diastolic >= 90:
                    reasons.append("High blood pressure detected")
                if "hypertension" in diagnosis:
                    reasons.append("Hypertension diagnosis")
                if "hypertension" in chronic:
                    reasons.append("Chronic hypertension history")
                if "dizziness" in symptoms:
                    reasons.append("Dizziness symptom may be related to blood pressure")

            elif medication == "metformin":
                if glucose >= 140:
                    reasons.append("High blood glucose level detected")
                if "diabetes" in diagnosis:
                    reasons.append("Diabetes diagnosis")
                if "diabetes" in chronic:
                    reasons.append("Chronic diabetes history")

            elif medication == "salbutamol":
                if oxygen <= 94:
                    reasons.append("Low oxygen saturation detected")
                if "shortness_of_breath" in symptoms:
                    reasons.append("Shortness of breath symptom reported")
                if "cough" in symptoms:
                    reasons.append("Cough symptom reported")
                if "asthma" in diagnosis or "asthma" in chronic:
                    reasons.append("Asthma diagnosis/history")

            elif medication == "omeprazole":
                if "stomach_pain" in symptoms or "nausea" in symptoms:
                    reasons.append("Gastrointestinal symptoms reported")
                if "gastritis" in diagnosis or "gastritis" in chronic:
                    reasons.append("Gastritis diagnosis/history")

            elif medication == "ibuprofen":
                if "headache" in symptoms:
                    reasons.append("Headache symptom reported")
                if "migraine" in diagnosis:
                    reasons.append("Migraine diagnosis")

                if systolic >= 140 or diastolic >= 90:
                    warnings.append(
                        "Use caution: NSAIDs may not be suitable for uncontrolled hypertension"
                    )
                if "gastritis" in diagnosis or "gastritis" in chronic:
                    warnings.append(
                        "Use caution: NSAIDs may irritate stomach in gastritis"
                    )

            elif medication == "azithromycin":
                if "infection" in diagnosis:
                    reasons.append("Infection diagnosis context")
                if "sore_throat" in symptoms or "cough" in symptoms:
                    reasons.append("Respiratory infection symptoms reported")

            if not reasons:
                reasons.append(
                    "Suggested based on the learned pattern from patient features"
                )

            enriched.append(
                {
                    **pred,
                    "reasons": reasons,
                    "warnings": warnings,
                    "requires_doctor_validation": True,
                }
            )

        return enriched

    @classmethod
    def is_model_loaded(cls) -> bool:
        return (
            cls._initialized
            and cls._model_manager
            and cls._model_manager.is_loaded()
        )