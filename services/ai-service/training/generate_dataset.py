import pandas as pd
import random

SYMPTOMS = [
    "fever", "headache", "cough", "sore_throat",
    "chest_pain", "shortness_of_breath", "dizziness",
    "stomach_pain", "nausea", "fatigue"
]

DIAGNOSES = [
    "flu", "cold", "hypertension", "diabetes",
    "gastritis", "asthma", "migraine", "infection"
]

CHRONIC = ["diabetes", "hypertension", "asthma", "gastritis"]

rows = []

for _ in range(8000):
    age = random.randint(18, 85)
    gender = random.choice(["male", "female"])

    glucose = random.randint(70, 230)
    systolic = random.randint(100, 185)
    diastolic = random.randint(60, 115)
    temperature = round(random.uniform(36.2, 40.0), 1)
    heart_rate = random.randint(60, 125)
    oxygen = random.randint(90, 100)

    symptoms = []
    diagnosis = []
    chronic = []
    meds = []

    # Fever / flu / infection
    if temperature >= 38:
        symptoms += ["fever", "headache", "fatigue"]
        diagnosis.append("flu")
        meds.append("paracetamol")

    if temperature >= 38.5 and random.random() < 0.4:
        symptoms += ["sore_throat", "cough"]
        diagnosis.append("infection")
        meds.append("azithromycin")

    # Hypertension
    if systolic >= 140 or diastolic >= 90:
        diagnosis.append("hypertension")
        chronic.append("hypertension")
        symptoms.append("dizziness")
        meds.append("amlodipine")

    # Diabetes
    if glucose >= 140:
        diagnosis.append("diabetes")
        chronic.append("diabetes")
        symptoms.append("fatigue")
        meds.append("metformin")

    # Asthma / breathing
    if oxygen <= 94 or random.random() < 0.08:
        symptoms += ["shortness_of_breath", "cough"]
        diagnosis.append("asthma")
        chronic.append("asthma")
        meds.append("salbutamol")

    # Migraine
    if "headache" in symptoms or random.random() < 0.12:
        symptoms.append("headache")
        diagnosis.append("migraine")
        meds.append("ibuprofen")

    # Gastritis
    if random.random() < 0.15:
        symptoms += ["stomach_pain", "nausea"]
        diagnosis.append("gastritis")
        chronic.append("gastritis")
        meds.append("omeprazole")

    if not meds:
        symptoms.append(random.choice(["fatigue", "headache", "cough"]))
        diagnosis.append("cold")
        meds.append("paracetamol")

    # remove duplicates
    symptoms = list(set(symptoms))
    diagnosis = list(set(diagnosis))
    chronic = list(set(chronic))
    meds = list(set(meds))

    row = {
        "age": age,
        "gender": gender,
        "bloodGlucoseLevel": glucose,
        "systolicBP": systolic,
        "diastolicBP": diastolic,
        "bodyTemperature": temperature,
        "heartRate": heart_rate,
        "oxygenSaturation": oxygen,
        "medications": ",".join(meds)
    }

    for s in SYMPTOMS:
        row[f"symptom_{s}"] = 1 if s in symptoms else 0

    for d in DIAGNOSES:
        row[f"diagnosis_{d}"] = 1 if d in diagnosis else 0

    for c in CHRONIC:
        row[f"chronic_{c}"] = 1 if c in chronic else 0

    row["gender_male"] = 1 if gender == "male" else 0
    row["gender_female"] = 1 if gender == "female" else 0

    rows.append(row)

df = pd.DataFrame(rows)
df.to_csv("training/dataset.csv", index=False)

print("Dataset generated:", len(df))
print("Columns:", len(df.columns))
print("Medications examples:", df["medications"].head())