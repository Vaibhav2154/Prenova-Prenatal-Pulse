from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import os
from dotenv import load_dotenv
load_dotenv()
from ollama import chat
from flask_cors import CORS

from supabase import create_client, Client

app = Flask(__name__)
CORS(app)

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
OLLAMA_MODEL_ID = os.environ.get("OLLAMA_MODEL_ID")


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
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return {'error': 'No valid token provided'}, 401
        
        token = auth_header.split(' ')[1]



        user_data = supabase.auth.get_user(token)

        if not user_data:
            return {'error': 'Invalid token'}, 401
        
        print("FREE TOKEN YALL", token)
        

        data = request.get_json()
        features = np.array(data["features"]).reshape(1, -1)
        
        # Scale the input features
        scaled_features = scaler.transform(features)

        # Make a prediction
        prediction = model.predict(scaled_features)[0]
        
        # Map prediction to health status
        health_status = {1: "Normal", 2: "Suspect", 3: "Pathological"}

        # Insert into ctg table
        # Map features array to CTG parameters in order
        feature_names = [
            'baseline_value', 'accelerations', 'fetal_movement', 'uterine_contractions',
            'light_decelerations', 'severe_decelerations', 'prolonged_decelerations',
            'abnormal_short_term_variability', 'mean_value_of_short_term_variability',
            'percentage_of_time_with_abnormal_long_term_variability', 'mean_value_of_long_term_variability',
            'histogram_width', 'histogram_min', 'histogram_max', 'histogram_number_of_peaks'
        ]
        
        # Create dictionary by zipping feature names with values
        feature_dict = dict(zip(feature_names, features.flatten()))
        
        ctg_data = {
            'UID': user_data.user.id,
            **feature_dict,  # Unpack the feature dictionary
            'prediction': int(prediction)
        }
        result_ctg = supabase.table('ctg').insert(ctg_data).execute()

        result = {"prediction": int(prediction), "status": health_status.get(int(prediction), "Unknown")}
        
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)})


@app.route("/diet_plan", methods=["POST"])
def pregnancy_diet():
    try:
        data = request.json

        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return {'error': 'No valid token provided'}, 401
        
        token = auth_header.split(' ')[1]

        user_data = supabase.auth.get_user(token)


        if not user_data:
            return {'error': 'Invalid token'}, 401
        

        prompt = f"You are a professional dietician and nutritionist. You suggest excellent diet plans for pregnant women that look after their well being and growth. You will now suggest a diet plan for a {data['trimester']} trimester pregnant woman weighing about {data['weight']} kg, who is feeling {data['health_conditions']} and has strict dietary preferences as follows: {data['dietary_preference']}. Do not suggest any foods that can cause harm or go against the dietary preferences. Suggest both a vegetarian only and a non-vegetarian diet plan separately for her and just give the plan."

        response = chat(model=OLLAMA_MODEL_ID, messages=[
            {'role':'user','content':prompt}
        ])

        # Store the diet plan in the database
        diet_data = {
            'UID': user_data.user.id,
            # 'trimester': data['trimester'],
            # 'weight': data['weight'],
            # 'health_conditions': data['health_conditions'],
            # 'dietary_preference': data['dietary_preference'],
            'diet_plan': response.message.content # Stored as markdown
        }

        return jsonify({"diet_plan": response.message.content})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/chat", methods=["POST"])
def chatbot():
    # try:
        data = request.json

        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return {'error': 'No valid token provided'}, 401
        
        token = auth_header.split(' ')[1]
        print("FREE TOKEN YALL", token)

        user_data = supabase.auth.get_user(token)

        if not user_data:
            return {'error': 'Invalid token'}, 401
        
        # Get the chat from the database
        chat_data = supabase.table('chats').select().eq('UID', user_data.user.id).order('created_at', desc=True).limit(1).execute()

        print("Chat data:", chat_data)
        if not chat_data.data:
            chat_history = []
        else:
            chat_history = chat_data.data[0]['chat_history']

        prompt = data['message']
        chat_history.append({'role':'user','content':prompt})
        response = chat(model=OLLAMA_MODEL_ID, messages=chat_history)

        print("Updated chat history:", chat_history)

        response = chat(model=OLLAMA_MODEL_ID, messages=chat_history)

        # Update the chat history
        chat_history.append({'role':'assistant','content':f"{response.message.content}"})
        result = supabase.table('chats').upsert({'UID': user_data.user.id, 'chat_history': chat_history}).execute()

        return jsonify({"response": response.message.content})
    # except Exception as e:
    #     return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True,port=5003,host="0.0.0.0")
