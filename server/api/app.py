from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import os
from dotenv import load_dotenv
load_dotenv()
from ollama import chat

from supabase import create_client, Client

app = Flask(__name__)

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
OLLAMA_MODEL_ID = os.environ.get("OLLAMA_MODEL_ID")


if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_KEY environment variables")

try:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    response = supabase.table("test").select("*").execute()
    print(response)
except Exception as e:
    print(f"Error connecting to Supabase: {str(e)}")
    supabase = None

# Load trained models and scalers
maternal_model = joblib.load("finalized_maternal_model.sav")
maternal_scaler = joblib.load("scaleX.pkl")

fetal_model = joblib.load("fetal_health_model.sav")
fetal_scaler = joblib.load("scaleX1.pkl")


@app.route("/predict_maternal", methods=["POST"])
def predict_maternal():
    try:
        # user_response = supabase.auth.get_user()
        data = request.json
        features = [
            float(data["age"]),
            float(data["systolic_bp"]),
            float(data["diastolic_bp"]),
            float(data["blood_glucose"]),
            float(data["body_temp"]),
            float(data["heart_rate"])
        ]
        features = np.array(features).reshape(1, -1)
        scaled_features = maternal_scaler.transform(features)
        prediction = maternal_model.predict(scaled_features)
        risk_mapping = {0: "Normal", 1: "Suspect", 2: "Pathological"}
        risk_level = risk_mapping[int(prediction[0])]
        return jsonify({"prediction": risk_level})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/predict_fetal", methods=["POST"])
def predict_fetal():
    try:
        data = request.json
        features = [
            float(data["baseline value"]),
            float(data["accelerations"]),
            float(data["fetal_movement"]),
            float(data["uterine_contractions"]),
            float(data["light_decelerations"]),
            float(data["severe_decelerations"]),
            float(data["prolongued_decelerations"]),
            float(data["abnormal_short_term_variability"]),
            float(data["mean_value_of_short_term_variability"]),
            float(data["percentage_of_time_with_abnormal_long_term_variability"]),
            float(data["mean_value_of_long_term_variability"]),
            float(data["histogram_width"]),
            float(data["histogram_min"]),
            float(data["histogram_max"]),
            float(data["histogram_number_of_peaks"]),
            float(data["histogram_mean"]),
            float(data["histogram_tendency"]),
            float(data["histogram_variance"]),
        ]

        feature_names = [
            "baseline value", "accelerations", "fetal_movement", "uterine_contractions",
            "light_decelerations", "severe_decelerations", "prolongued_decelerations",
            "abnormal_short_term_variability", "mean_value_of_short_term_variability",
            "percentage_of_time_with_abnormal_long_term_variability",
            "mean_value_of_long_term_variability", "histogram_width",
            "histogram_min", "histogram_max", "histogram_number_of_peaks",
            "histogram_mean", "histogram_tendency", "histogram_variance"
        ]
        
        features_df = pd.DataFrame([features], columns=feature_names)
        scaled_features = fetal_scaler.transform(features_df)
        prediction = fetal_model.predict(scaled_features)
        
        fetal_mapping = {1: "Normal", 2: "Suspect", 3: "Pathological"}
        health_status = fetal_mapping[int(prediction[0])]

        return jsonify({"prediction": health_status})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/diet_plan", methods=["POST"])
def pregnancy_diet():
    try:
        data = request.json
        prompt = f"Suggest a diet plan for a {data['trimester']} trimester pregnant woman weighing {data['weight']} kg, with health conditions {data['health_conditions']} and dietary preference {data['dietary_preference']}."
        
        response = chat(model=OLLAMA_MODEL_ID, messages=[
        {
            'role': 'user',
            'content': prompt,
        },
        ])
        return jsonify({"diet_plan": response.message.content})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/chat", methods=["POST"])
def chatbot():
    try:
        data = request.json
        response = chat(model=OLLAMA_MODEL_ID, messages=[
        {
            'role': 'user',
            'content': data['message'],
        },
        ])
        return jsonify({"response": response.message.content})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True,port=5003)
