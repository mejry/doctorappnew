import pandas as pd
import numpy as np
from typing import Dict, Any, List
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class FeatureEngineer:
    def __init__(self):
        pass

    def prepare_patient_features(
        self,
        patient_data: Dict[str, Any],
        medical_history: Dict[str, Any],
        consultation_data: Dict[str, Any] = None
    ) -> List[float]:

        try:
            features = {}

            consultation_data = consultation_data or {}

            symptoms = consultation_data.get("symptoms", [])
            diagnosis = consultation_data.get("diagnosis", [])
            chronic = medical_history.get("chronicDiseases", [])

            # DEMOGRAPHICS
            features["age"] = patient_data.get("age", 45)

            gender = patient_data.get("gender", "").lower()

            features["gender_male"] = 1 if gender == "male" else 0
            features["gender_female"] = 1 if gender == "female" else 0

            # VITALS
            features["bloodGlucoseLevel"] = medical_history.get("bloodGlucoseLevel", 100)

            features["heartRate"] = medical_history.get("heartRate", 75)

            features["oxygenSaturation"] = medical_history.get("oxygenSaturation", 98)

            features["bodyTemperature"] = medical_history.get("bodyTemperature", 37)

            bp = medical_history.get("bloodPressure", "120/80")

            if isinstance(bp, str) and "/" in bp:
                systolic, diastolic = bp.split("/")
                features["systolicBP"] = float(systolic)
                features["diastolicBP"] = float(diastolic)
            else:
                features["systolicBP"] = 120
                features["diastolicBP"] = 80

            # SYMPTOMS
            symptom_list = [
                "fever",
                "headache",
                "cough",
                "sore_throat",
                "chest_pain",
                "shortness_of_breath",
                "dizziness",
                "stomach_pain",
                "nausea",
                "fatigue"
            ]

            for s in symptom_list:
                features[f"symptom_{s}"] = 1 if s in symptoms else 0

            # DIAGNOSIS
            diagnosis_list = [
                "flu",
                "cold",
                "hypertension",
                "diabetes",
                "gastritis",
                "asthma",
                "migraine",
                "infection"
            ]

            for d in diagnosis_list:
                features[f"diagnosis_{d}"] = 1 if d in diagnosis else 0

            # CHRONIC
            chronic_list = [
                "diabetes",
                "hypertension",
                "asthma",
                "gastritis"
            ]

            for c in chronic_list:
                features[f"chronic_{c}"] = 1 if c in chronic else 0

            feature_vector = self._create_feature_vector(features)

            logger.info(f"✅ Features préparées: {len(feature_vector)}")

            return feature_vector

        except Exception as e:
            logger.error(f"❌ Erreur features: {e}")
            raise

    def _create_feature_vector(self, features: Dict[str, float]) -> List[float]:

        expected_features = [
            "age",
            "bloodGlucoseLevel",
            "systolicBP",
            "diastolicBP",
            "bodyTemperature",
            "heartRate",
            "oxygenSaturation",

            "symptom_fever",
            "symptom_headache",
            "symptom_cough",
            "symptom_sore_throat",
            "symptom_chest_pain",
            "symptom_shortness_of_breath",
            "symptom_dizziness",
            "symptom_stomach_pain",
            "symptom_nausea",
            "symptom_fatigue",

            "diagnosis_flu",
            "diagnosis_cold",
            "diagnosis_hypertension",
            "diagnosis_diabetes",
            "diagnosis_gastritis",
            "diagnosis_asthma",
            "diagnosis_migraine",
            "diagnosis_infection",

            "chronic_diabetes",
            "chronic_hypertension",
            "chronic_asthma",
            "chronic_gastritis",

            "gender_male",
            "gender_female"
        ]

        return [features.get(f, 0.0) for f in expected_features]