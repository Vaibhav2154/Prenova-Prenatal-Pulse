from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import os
from dotenv import load_dotenv
load_dotenv()
from ollama import chat
from flask_cors import CORS
import google.generativeai as genai
from supabase import create_client, Client

app = Flask(__name__)
CORS(app)

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
OLLAMA_MODEL_ID = os.environ.get("OLLAMA_MODEL_ID")


genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
chatmodel = genai.GenerativeModel("gemini-2.0-flash")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_KEY environment variables")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# Load trained models and scalers
maternal_model = joblib.load("finalized_maternal_model.sav")
maternal_scaler = joblib.load("scaleX.pkl")

# Load the trained model and scaler
model_path = "fetal_health_model.sav"
scaler_path = "scaleX1.pkl"

with open(model_path, "rb") as model_file:
    model = joblib.load(model_file)

with open(scaler_path, "rb") as scaler_file:
    scaler = joblib.load(scaler_file)
    # print("Scaler expects feature count:", scaler.n_features_in_)



# @app.route("/create_profile",methods=["POST"])
# def create_profile():
#     try:
#         auth_header = request.headers.get('Authorization')
#         if not auth_header or not auth_header.startswith('Bearer '):
#             return {'error': 'No valid token provided'}, 401
        
#         token = auth_header.split(' ')[1]

#         user_data = supabase.auth.get_user(token)
#         if not user_data:
#             return {'error': 'Invalid token'}, 401

#         # print(user_data)
#         # return jsonify({"message": "Profile created successfully"}), 200
    
#         data = request.json
#         print("recieved data", data)
#         # Extract data from request
#         user_id = user_data.user.id
#         profile_data = {
#             'profile_image': data.get('profile_image'),
#             'pregnancy_trimester': data.get('pregnancy_trimester'),
#             'current_weight': data.get('current_weight'),
#             'current_height': data.get('current_height'),
#             'age': data.get('age'),
#             'user_name': data.get('user_name'),
#             "expected_due_date" : data.get('expected_due_date'),
#             'id': user_id
#         }

#         # Insert into profiles table
#         result = supabase.table('profiles').upsert(profile_data).execute()
        
#         return jsonify({"message": "Profile created successfully", "data": result.data}), 200
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500
    
@app.route("/create_doctor_profile", methods=["POST"])
def create_doctor_profile():
    '''Simple endpoint for us to dump some data into a table'''
    try:
        data = request.json
        doctor_data = {
            'name': data.get('name'),
            'phone': data.get('phone'),
            'specialty': data.get('specialty'),
            'location': data.get('location'),
            'profile_image_url': data.get('profile_image_url'),
        }

        result = supabase.table('doctors').upsert(doctor_data).execute()
        
        return jsonify({"message": "Doctor profile created successfully", "data": result.data}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/predict_maternal", methods=["POST"])
def predict_maternal():
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return {'error': 'No valid token provided'}, 401
        
        token = auth_header.split(' ')[1]

        user_data = supabase.auth.get_user(token)
        print("FREE TOKEN", token)

        if not user_data:
            return {'error': 'Invalid token'}, 401

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

        # Insert into vitals table   
        vital_data = {
            'UID': user_data.user.id,
            'systolic_bp': data["systolic_bp"],
            'diastolic_bp': data["diastolic_bp"],
            'blood_glucose': data["blood_glucose"],
            'body_temp': data["body_temp"],
            'heart_rate': data["heart_rate"],
            'prediction': int(prediction[0])
        }
        result = supabase.table('vitals').insert(vital_data).execute()

        return jsonify({"prediction": risk_level})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

# @app.route("/get_vitals", methods=["GET"])
# def get_vitals():
#     try:
#         auth_header = request.headers.get('Authorization')
#         if not auth_header or not auth_header.startswith('Bearer '):
#             return {'error': 'No valid token provided'}, 401
        
#         token = auth_header.split(' ')[1]

#         user_data = supabase.auth.get_user(token)

#         if not user_data:
#             return {'error': 'Invalid token'}, 401

#         result = supabase.table('vitals').select().eq('UID', user_data.user.id).order('created_at', desc=True).execute()
#         return jsonify(result.data)
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500
    
# @app.route("/get_contractions_data", methods=["GET"])
# def get_contractions_data():
#     '''Not tested'''
#     try:
#         auth_header = request.headers.get('Authorization')
#         if not auth_header or not auth_header.startswith('Bearer '):
#             return {'error': 'No valid token provided'}, 401
        
#         token = auth_header.split(' ')[1]

#         user_data = supabase.auth.get_user(token)

#         if not user_data:
#             return {'error': 'Invalid token'}, 401

#         result = supabase.table('contractions').select().eq('UID', user_data.user.id).order('created_at', desc=True).execute()
#         return jsonify(result.data)
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @app.route("/get_ctg_data", methods=["GET"])
# def get_ctg_data():
#     '''Not tested'''
#     try:
#         auth_header = request.headers.get('Authorization')
#         if not auth_header or not auth_header.startswith('Bearer '):
#             return {'error': 'No valid token provided'}, 401
        
#         token = auth_header.split(' ')[1]

#         user_data = supabase.auth.get_user(token)

#         if not user_data:
#             return {'error': 'Invalid token'}, 401

#         result = supabase.table('fetal_health').select().eq('UID', user_data.user.id).order('created_at', desc=True).execute()
#         return jsonify(result.data)
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500


@app.route("/predict_fetal", methods=["POST"])
def predict_fetal():
    try:
        # Validate Authorization Header
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401

        token = auth_header.split(' ')[1]
        
        # Validate Token & Get User Data
        try:
            user_data = supabase.auth.get_user(token)
            if not user_data or not user_data.user:
                return jsonify({'error': 'Invalid token'}), 401
        except Exception:
            return jsonify({'error': 'Failed to validate token'}), 401

        # Parse Input Data
        data = request.get_json()
        if not data or "features" not in data:
            return jsonify({'error': 'Missing required feature data'}), 400

        # Ensure feature list has correct length
        features = np.array(data["features"], dtype=float)
        expected_feature_length = 15  # Adjust as needed
        if features.shape[0] != expected_feature_length:
            return jsonify({'error': f'Invalid feature length, expected {expected_feature_length}'}), 400
        
        features = features.reshape(1, -1)

        # Scale features
        try:
            scaled_features = scaler.transform(features)
        except Exception as e:
            return jsonify({'error': f'Feature scaling failed: {str(e)}'}), 500

        # Make Prediction
        try:
            prediction = int(model.predict(scaled_features)[0])  # Ensure Python int
        except Exception as e:
            return jsonify({'error': f'Prediction failed: {str(e)}'}), 500

        # Map prediction to health status
        health_status = {1: "Normal", 2: "Suspect", 3: "Pathological"}
        prediction_result = health_status.get(prediction, "Unknown")

        # Define Feature Names
        feature_names = [
            'baseline_value', 'accelerations', 'fetal_movement', 'uterine_contractions',
            'light_decelerations', 'severe_decelerations', 'prolonged_decelerations',
            'abnormal_short_term_variability', 'mean_value_of_short_term_variability',
            'percentage_of_time_with_abnormal_long_term_variability', 'mean_value_of_long_term_variability',
            'histogram_width', 'histogram_min', 'histogram_max', 'histogram_number_of_peaks'
        ]

        # Map features to dictionary and ensure all values are Python types
        feature_dict = {k: float(v) for k, v in zip(feature_names, features.flatten())}

        # Prepare data for Supabase
        ctg_data = {
            'UID': user_data.user.id,
            **feature_dict,
            'prediction': prediction
        }

        # Insert Data into Supabase
        try:
            supabase.table('ctg').insert(ctg_data).execute()
        except Exception as e:
            return jsonify({'error': f'Database insert failed: {str(e)}'}), 500

        return jsonify({"prediction": prediction, "status": prediction_result})

    except Exception as e:
        return jsonify({"error": f"Unexpected error: {str(e)}"}), 500



from flask import request, jsonify
import google.generativeai as genai

# Make sure the Gemini model and API are configured globally
model = genai.GenerativeModel("gemini-1.5-flash")

@app.route("/diet_plan", methods=["POST"])
def pregnancy_diet():
    try:
        data = request.json

        # --- Auth header validation ---
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # --- Prompt for Gemini ---
        prompt = (
            f"You are a professional dietician and nutritionist. Suggest safe and personalized diet plans for pregnant women. "
            f"Now, generate a diet plan for a woman in her **{data['trimester']} trimester**, weighing **{data['weight']} kg**, "
            f"who is feeling **{data['health_conditions']}** and follows these dietary preferences: **{data['dietary_preference']}**. "
            f"Give two separate diet plans: one **vegetarian** and one **non-vegetarian**. Do not include anything that violates her preferences. "
            f"Present the results clearly in markdown format with headings and bullet points."
        )

        # --- Gemini API Call ---
        response = chatmodel.generate_content({"role": "user", "parts": [{"text": prompt}]})
        diet_plan_text = response.text

        # --- Optionally save to DB (you can add more fields if needed) ---
        supabase.table('diet_plans').insert({
            'UID': user_data.user.id,
            'diet_plan': diet_plan_text
        }).execute()

        return jsonify({"diet_plan": diet_plan_text})

    except Exception as e:
        print(e)
        return jsonify({"error": str(e)}), 500



    
SYSTEM_PROMPT = {
    "role": "user",
    "content": "You are Prenova, an AI assistant that is here to help users with their pregnancy journey. "
               "You will only provide accurate and helpful information related to pregnancy, avoiding any "
               "medical advice or unrelated topics. Be polite and respectful at all times."
}

@app.route('/chat', methods=['GET'])
def chatbot_get():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'No valid token provided'}), 401
    
    token = auth_header.split(' ')[1]
    user_data = supabase.auth.get_user(token)

    if not user_data:
        return jsonify({'error': 'Invalid token'}), 401

    chat_data = supabase.table('chats').select().eq('UID', user_data.user.id).order('created_at', desc=True).limit(1).execute()

    if chat_data.data:
        print(chat_data)
        return jsonify(chat_data.data[0]['chat_history'][1:])
    else:
        return jsonify([SYSTEM_PROMPT])  # return initial system prompt if no chats

@app.route("/chat", methods=["POST"])
def chatbot_post():
    try:
        data = request.json
        auth_header = request.headers.get('Authorization')

        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401

        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Retrieve existing chat or use system prompt
        chat_data = supabase.table('chats').select().eq('UID', user_data.user.id).order('created_at', desc=True).limit(1).execute()
        chat_history = chat_data.data[0]['chat_history'] if chat_data.data else [SYSTEM_PROMPT]

        # Append user's message
        user_msg = {"role": "user", "content": data['message']}
        chat_history.append(user_msg)

        # Convert chat history to Gemini format
        gemini_messages = []
        for msg in chat_history:
            if msg["role"] == "user":
                gemini_messages.append({"role": "user", "parts": [{"text": msg["content"]}]})
            elif msg["role"] == "assistant":
                gemini_messages.append({"role": "model", "parts": [{"text": msg["content"]}]})
            # System prompt will be treated as user message
            else:
                gemini_messages.append({"role": "user", "parts": [{"text": msg["content"]}]})

        # Get Gemini response
        response = chatmodel.generate_content(gemini_messages)

        assistant_msg = {"role": "assistant", "content": response.text}
        chat_history.append(assistant_msg)

        # Upsert chat history
        supabase.table('chats').upsert({
            'UID': user_data.user.id,
            'chat_history': chat_history
        }).execute()

        return jsonify({"response": response.text})
    except Exception as e:
        print(e)
        return jsonify({"error": str(e)}), 500
    
@app.route('/')
def ind():
    return "Hello governer"

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
