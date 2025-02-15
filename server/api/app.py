from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import google.generativeai as genai  # Import Gemini AI SDK
import os

app = Flask(__name__)

# Load trained models and scalers
maternal_model = joblib.load("finalized_maternal_model.sav")
maternal_scaler = joblib.load("scaleX.pkl")

fetal_model = joblib.load("fetal_health_model.sav")
fetal_scaler = joblib.load("scaleX1.pkl")

# Set up Gemini API Key (Replace with your actual API key)
GEN_AI_API_KEY = "AIzaSyC5I3IvJ_QnEsb28ncuwRgauLCwFLtp6pk"
genai.configure(api_key=GEN_AI_API_KEY)

@app.route("/predict_maternal", methods=["POST"])
def predict_maternal():
    try:
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
        risk_mapping = {0: "low risk", 1: "mid risk", 2: "high risk"}
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
            float(data["histogram_number_of_peaks"])
        ]

        feature_names = [
            "baseline_value", "accelerations", "fetal_movement", "uterine_contractions",
            "light_decelerations", "severe_decelerations", "prolongued_decelerations",
            "abnormal_short_term_variability", "mean_value_of_short_term_variability",
            "percentage_of_time_with_abnormal_long_term_variability",
            "mean_value_of_long_term_variability", "histogram_width",
            "histogram_min", "histogram_max", "histogram_number_of_peaks"
        ]
        
        features_df = pd.DataFrame([features], columns=feature_names)
        scaled_features = fetal_scaler.transform(features_df)
        prediction = fetal_model.predict(scaled_features)
        
        fetal_mapping = {1: "Normal", 2: "Suspect", 3: "Pathological"}
        health_status = fetal_mapping[int(prediction[0])]

        return jsonify({"prediction": health_status})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
genai.configure(api_key="")  # Replace with your actual API key
model = genai.GenerativeModel("gemini-pro")

@app.route("/pregnancy-diet", methods=["POST"])
def pregnancy_diet():
    try:
        data = request.json
        prompt = f"Suggest a diet plan for a {data['trimester']} trimester pregnant woman weighing {data['weight']} kg, with health conditions {data['health_conditions']} and dietary preference {data['dietary_preference']}."
        
        response = model.generate_content(prompt)
        return jsonify({"diet_plan": response.text})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
