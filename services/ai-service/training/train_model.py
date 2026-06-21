import pandas as pd
import json
import joblib
import os

from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import MultiLabelBinarizer
from sklearn.multioutput import MultiOutputClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

df = pd.read_csv("training/dataset.csv")

# Remove target + non-numeric text columns
X = df.drop(columns=["medications", "gender"], errors="ignore")

# Force all features to numeric
X = X.apply(pd.to_numeric, errors="coerce").fillna(0)

feature_columns = list(X.columns)

y_raw = df["medications"].apply(lambda x: str(x).split(","))

mlb = MultiLabelBinarizer()
y = mlb.fit_transform(y_raw)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

model = MultiOutputClassifier(
    RandomForestClassifier(
        n_estimators=150,
        random_state=42,
        class_weight="balanced"
    )
)

model.fit(X_train, y_train)

y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print("Accuracy:", accuracy)
print("Features:", len(feature_columns))
print("Medications:", list(mlb.classes_))

os.makedirs("models", exist_ok=True)

joblib.dump(model, "models/model.pkl")

with open("models/medications.json", "w") as f:
    json.dump(list(mlb.classes_), f)

with open("models/columns.json", "w") as f:
    json.dump(feature_columns, f)

print("Model saved successfully")