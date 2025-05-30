from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import os
from dotenv import load_dotenv
load_dotenv()
from flask_cors import CORS
import google.generativeai as genai
from supabase import create_client, Client
import uuid
from datetime import datetime

app = Flask(__name__)
CORS(app)

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
chatmodel = genai.GenerativeModel("gemini-2.0-flash")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_KEY environment variables")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Load trained models and scalers (keeping existing model loading code)
maternal_model = joblib.load("finalized_maternal_model.sav")
maternal_scaler = joblib.load("scaleX.pkl")

model_path = "fetal_health_model.sav"
scaler_path = "scaleX1.pkl"

with open(model_path, "rb") as model_file:
    model = joblib.load(model_file)

with open(scaler_path, "rb") as scaler_file:
    scaler = joblib.load(scaler_file)

fetal_model = joblib.load("fetal_health_model.sav")
fetal_scaler = joblib.load("scaleX1.pkl")

# System prompt for the AI assistant
SYSTEM_PROMPT = {
    "role": "system",
    "content": "You are NOVA, an AI assistant that is here to help users with their pregnancy journey. "
               "You will only provide accurate and helpful information related to pregnancy, avoiding any "
               "medical advice or unrelated topics. Be polite and respectful at all times. "
               "Format your responses using markdown for better readability with headings, bullet points, "
               "and emphasis where appropriate."
}

def generate_chat_title(first_message):
    """Generate a meaningful title for the chat session based on the first message"""
    try:
        prompt = f"Generate a short, descriptive title (max 6 words) for a chat that starts with: '{first_message[:100]}'"
        response = chatmodel.generate_content([{"role": "user", "parts": [{"text": prompt}]}])
        title = response.text.strip().replace('"', '').replace("'", "")
        return title[:50]  # Limit title length
    except:
        return "New Chat"

# ===== CHAT SESSION ENDPOINTS =====

@app.route('/chat/sessions', methods=['GET'])
def get_chat_sessions():
    """Get all chat sessions for the authenticated user"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Get all chat sessions for the user, ordered by most recent
        sessions_data = supabase.table('chat_sessions').select(
            'id, title, created_at, updated_at'
        ).eq('user_id', user_data.user.id).order('updated_at', desc=True).execute()

        return jsonify(sessions_data.data), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/chat/sessions', methods=['POST'])
def create_chat_session():
    """Create a new chat session"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        session_id = str(uuid.uuid4())
        
        # Create new session with system prompt
        session_data = {
            'id': session_id,
            'user_id': user_data.user.id,
            'title': 'New Chat',
            'messages': [SYSTEM_PROMPT],
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }

        result = supabase.table('chat_sessions').insert(session_data).execute()
        
        return jsonify(result.data[0]), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/chat/sessions/<session_id>', methods=['GET'])
def get_chat_session(session_id):
    """Get a specific chat session with its messages"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Get specific session
        session_data = supabase.table('chat_sessions').select(
            'id, title, messages, created_at, updated_at'
        ).eq('id', session_id).eq('user_id', user_data.user.id).execute()

        if not session_data.data:
            return jsonify({'error': 'Session not found'}), 404

        session = session_data.data[0]
        
        # Filter out system prompt from messages for display
        display_messages = [msg for msg in session['messages'] if msg.get('role') != 'system']
        
        return jsonify({
            'id': session['id'],
            'title': session['title'],
            'messages': display_messages,
            'created_at': session['created_at'],
            'updated_at': session['updated_at']
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/chat/sessions/<session_id>', methods=['DELETE'])
def delete_chat_session(session_id):
    """Delete a specific chat session"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Delete the session
        result = supabase.table('chat_sessions').delete().eq(
            'id', session_id
        ).eq('user_id', user_data.user.id).execute()

        if not result.data:
            return jsonify({'error': 'Session not found'}), 404

        return jsonify({'message': 'Session deleted successfully'}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/chat/sessions/<session_id>/message', methods=['POST'])
def send_message_to_session(session_id):
    """Send a message to a specific chat session"""
    try:
        data = request.json
        auth_header = request.headers.get('Authorization')

        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401

        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Get the session
        session_data = supabase.table('chat_sessions').select(
            'id, title, messages'
        ).eq('id', session_id).eq('user_id', user_data.user.id).execute()

        if not session_data.data:
            return jsonify({'error': 'Session not found'}), 404

        session = session_data.data[0]
        messages = session['messages'] or [SYSTEM_PROMPT]

        # Add user message
        user_msg = {"role": "user", "content": data['message']}
        messages.append(user_msg)

        # Convert to Gemini format for API call
        gemini_messages = []
        for msg in messages:
            if msg["role"] == "user":
                gemini_messages.append({"role": "user", "parts": [{"text": msg["content"]}]})
            elif msg["role"] == "assistant":
                gemini_messages.append({"role": "model", "parts": [{"text": msg["content"]}]})
            elif msg["role"] == "system":
                # Include system prompt as user message to Gemini
                gemini_messages.insert(0, {"role": "user", "parts": [{"text": msg["content"]}]})

        # Get AI response
        response = chatmodel.generate_content(gemini_messages)
        assistant_msg = {"role": "assistant", "content": response.text}
        messages.append(assistant_msg)

        # Generate title if this is the first user message (after system prompt)
        current_title = session['title']
        if current_title == 'New Chat' and len([m for m in messages if m.get('role') == 'user']) == 1:
            current_title = generate_chat_title(data['message'])

        # Update session in database
        update_data = {
            'messages': messages,
            'title': current_title,
            'updated_at': datetime.utcnow().isoformat()
        }

        supabase.table('chat_sessions').update(update_data).eq('id', session_id).execute()

        return jsonify({
            "content": response.text,
            "title": current_title
        }), 200

    except Exception as e:
        print(f"Error in send_message_to_session: {e}")
        return jsonify({"error": str(e)}), 500

# ===== LEGACY CHAT ENDPOINTS (for backward compatibility) =====

@app.route('/chat', methods=['GET'])
def chatbot_get():
    """Legacy endpoint - redirects to session-based approach"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Get the most recent session
        sessions_data = supabase.table('chat_sessions').select(
            'messages'
        ).eq('user_id', user_data.user.id).order('updated_at', desc=True).limit(1).execute()

        if sessions_data.data:
            messages = sessions_data.data[0]['messages']
            # Filter out system prompt
            display_messages = [msg for msg in messages if msg.get('role') != 'system']
            return jsonify(display_messages)
        else:
            return jsonify([])

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/chat", methods=["POST"])
def chatbot_post():
    """Legacy endpoint - creates new session if none exists"""
    try:
        data = request.json
        auth_header = request.headers.get('Authorization')

        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401

        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Get or create a session
        sessions_data = supabase.table('chat_sessions').select(
            'id, messages'
        ).eq('user_id', user_data.user.id).order('updated_at', desc=True).limit(1).execute()

        if sessions_data.data:
            # Use existing session
            session_id = sessions_data.data[0]['id']
            messages = sessions_data.data[0]['messages'] or [SYSTEM_PROMPT]
        else:
            # Create new session
            session_id = str(uuid.uuid4())
            messages = [SYSTEM_PROMPT]
            
            session_data = {
                'id': session_id,
                'user_id': user_data.user.id,
                'title': 'New Chat',
                'messages': messages,
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }
            supabase.table('chat_sessions').insert(session_data).execute()

        # Add user message
        user_msg = {"role": "user", "content": data['message']}
        messages.append(user_msg)

        # Convert to Gemini format
        gemini_messages = []
        for msg in messages:
            if msg["role"] == "user":
                gemini_messages.append({"role": "user", "parts": [{"text": msg["content"]}]})
            elif msg["role"] == "assistant":
                gemini_messages.append({"role": "model", "parts": [{"text": msg["content"]}]})
            elif msg["role"] == "system":
                gemini_messages.insert(0, {"role": "user", "parts": [{"text": msg["content"]}]})

        # Get AI response
        response = chatmodel.generate_content(gemini_messages)
        assistant_msg = {"role": "assistant", "content": response.text}
        messages.append(assistant_msg)

        # Generate title if needed
        title = generate_chat_title(data['message']) if len([m for m in messages if m.get('role') == 'user']) == 1 else None

        # Update session
        update_data = {
            'messages': messages,
            'updated_at': datetime.utcnow().isoformat()
        }
        if title:
            update_data['title'] = title

        supabase.table('chat_sessions').update(update_data).eq('id', session_id).execute()

        return jsonify({"response": response.text})

    except Exception as e:
        print(e)
        return jsonify({"error": str(e)}), 500

# ===== EXISTING ENDPOINTS (keeping all your other endpoints) =====

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
            scaled_features = fetal_scaler.transform(features)  # Use fetal_scaler instead of scaler
        except Exception as e:
            return jsonify({'error': f'Feature scaling failed: {str(e)}'}), 500

        # Make Prediction - use fetal_model instead of model
        try:
            prediction = int(fetal_model.predict(scaled_features)[0])  # Use fetal_model
        except Exception as e:
            return jsonify({'error': f'Prediction failed: {str(e)}'}), 500

        # Map prediction to health status
        health_status = {0: "Normal", 1: "Suspect", 2: "Pathological"}
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

# 
@app.route('/diet/sessions', methods=['GET'])
def get_diet_sessions():
    """Get all diet sessions for the authenticated user"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Include diet_plan field in the selection
        sessions_data = supabase.table('diet_sessions').select(
            'id, title, trimester, weight, health_conditions, dietary_preference, diet_plan, created_at, updated_at'
        ).eq('user_id', user_data.user.id).order('updated_at', desc=True).execute()

        return jsonify(sessions_data.data), 200

    except Exception as e:
        print(f"Error fetching diet sessions: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/diet/sessions', methods=['POST'])
def create_diet_session():
    """Create a new diet session and generate recommendations"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        data = request.json
        session_id = str(uuid.uuid4())
        
        print(f"Creating diet session for user: {user_data.user.id}")
        print(f"Request data: {data}")
        
        # Generate structured diet plan
        diet_plan = generate_structured_diet_plan(
            data['trimester'],
            data['weight'],
            data['health_conditions'],
            data['dietary_preference']
        )
        
        print(f"Generated diet plan: {len(diet_plan.get('meal_plans', []))} meal plans, {len(diet_plan.get('tips', []))} tips")
        
        # Create session title
        title = f"{data['trimester']} Trimester - {data['weight']}kg"
        
        # Create new session
        session_data = {
            'id': session_id,
            'user_id': user_data.user.id,
            'title': title,
            'trimester': data['trimester'],
            'weight': data['weight'],
            'health_conditions': data['health_conditions'],
            'dietary_preference': data['dietary_preference'],
            'diet_plan': diet_plan,
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }

        result = supabase.table('diet_sessions').insert(session_data).execute()
        print(f"Successfully created diet session: {session_id}")
        
        return jsonify(result.data[0]), 201

    except Exception as e:
        print(f"Error creating diet session: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/diet/sessions/<session_id>', methods=['GET'])
def get_diet_session(session_id):
    """Get a specific diet session with its recommendations"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Get specific session
        session_data = supabase.table('diet_sessions').select('*').eq(
            'id', session_id
        ).eq('user_id', user_data.user.id).execute()

        if not session_data.data:
            return jsonify({'error': 'Session not found'}), 404

        return jsonify(session_data.data[0]), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/diet/sessions/<session_id>', methods=['DELETE'])
def delete_diet_session(session_id):
    """Delete a specific diet session"""
    try:
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No valid token provided'}), 401
        
        token = auth_header.split(' ')[1]
        user_data = supabase.auth.get_user(token)

        if not user_data:
            return jsonify({'error': 'Invalid token'}), 401

        # Delete the session
        result = supabase.table('diet_sessions').delete().eq(
            'id', session_id
        ).eq('user_id', user_data.user.id).execute()

        if not result.data:
            return jsonify({'error': 'Session not found'}), 404

        return jsonify({'message': 'Session deleted successfully'}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

def generate_structured_diet_plan(trimester, weight, health_conditions, dietary_preference):
    """Generate a structured diet plan using Gemini AI"""
    try:
        # Improved prompt with clearer instructions
        prompt = f"""
        You are a professional nutritionist. Create a comprehensive pregnancy diet plan for:
        - Trimester: {trimester}
        - Weight: {weight}kg
        - Health Conditions: {health_conditions or 'None'}
        - Dietary Preference: {dietary_preference or 'No specific preference'}
        
        IMPORTANT: Respond ONLY with a valid JSON object. Do not include any markdown formatting or explanations.
        
        {{
            "overview": {{
                "calories_per_day": "2200-2500",
                "key_nutrients": ["Folic Acid", "Iron", "Calcium", "Protein", "Omega-3"],
                "foods_to_avoid": ["Raw fish", "Unpasteurized dairy", "High mercury fish"]
            }},
            "meal_plans": [
                {{
                    "type": "Balanced Plan",
                    "meals": {{
                        "breakfast": {{"name": "Nutritious Breakfast", "calories": "400", "items": ["Whole grain toast", "Scrambled eggs", "Fresh fruits"]}},
                        "lunch": {{"name": "Healthy Lunch", "calories": "500", "items": ["Grilled chicken", "Brown rice", "Steamed vegetables"]}},
                        "dinner": {{"name": "Light Dinner", "calories": "450", "items": ["Fish", "Quinoa", "Green salad"]}},
                        "snacks": [{{"name": "Morning Snack", "items": ["Greek yogurt", "Nuts"]}}, {{"name": "Evening Snack", "items": ["Apple", "Peanut butter"]}}]
                    }}
                }}
            ],
            "tips": [
                "Drink plenty of water throughout the day",
                "Eat small, frequent meals to manage nausea",
                "Take prenatal vitamins as recommended by your doctor",
                "Avoid alcohol and limit caffeine intake"
            ],
            "supplements": [
                {{"name": "Folic Acid", "dosage": "400-800 mcg daily", "reason": "Prevents neural tube defects"}},
                {{"name": "Iron", "dosage": "27 mg daily", "reason": "Prevents anemia and supports blood volume expansion"}},
                {{"name": "Calcium", "dosage": "1000 mg daily", "reason": "Supports baby's bone development"}}
            ]
        }}
        """
        
        print(f"Generating diet plan for: {trimester} trimester, {weight}kg")
        response = chatmodel.generate_content(prompt)
        diet_plan_text = response.text.strip()
        
        print(f"Raw AI response: {diet_plan_text[:200]}...")
        
        # More robust JSON extraction
        json_start = diet_plan_text.find('{')
        json_end = diet_plan_text.rfind('}') + 1
        
        if json_start != -1 and json_end > json_start:
            diet_plan_text = diet_plan_text[json_start:json_end]
        
        # Clean common markdown artifacts
        diet_plan_text = diet_plan_text.replace('```json', '').replace('```', '').strip()
        
        print(f"Cleaned JSON: {diet_plan_text[:200]}...")
        
        try:
            diet_plan = json.loads(diet_plan_text)
            print("Successfully parsed diet plan JSON")
            return diet_plan
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            print(f"Failed to parse: {diet_plan_text}")
            # Return a more comprehensive fallback
            return create_fallback_diet_plan(trimester, weight, dietary_preference)
            
    except Exception as e:
        print(f"Error generating diet plan: {e}")
        return create_fallback_diet_plan(trimester, weight, dietary_preference)

def create_fallback_diet_plan(trimester, weight, dietary_preference):
    """Create a fallback diet plan when AI generation fails"""
    return {
        "overview": {
            "calories_per_day": "2200-2500",
            "key_nutrients": ["Folic Acid", "Iron", "Calcium", "Protein", "Omega-3", "Vitamin D"],
            "foods_to_avoid": ["Raw fish", "Unpasteurized dairy", "High mercury fish", "Raw eggs", "Deli meats"]
        },
        "meal_plans": [
            {
                "type": "Balanced Plan",
                "meals": {
                    "breakfast": {
                        "name": "Nutritious Morning Start",
                        "calories": "400",
                        "items": ["Whole grain cereal with milk", "Fresh berries", "Orange juice"]
                    },
                    "lunch": {
                        "name": "Balanced Midday Meal",
                        "calories": "500",
                        "items": ["Grilled chicken salad", "Whole wheat bread", "Mixed vegetables"]
                    },
                    "dinner": {
                        "name": "Light Evening Meal",
                        "calories": "450",
                        "items": ["Baked salmon", "Sweet potato", "Steamed broccoli"]
                    },
                    "snacks": [
                        {"name": "Morning Snack", "items": ["Greek yogurt", "Almonds"]},
                        {"name": "Afternoon Snack", "items": ["Apple slices", "Cheese"]}
                    ]
                }
            }
        ],
        "tips": [
            "Stay hydrated by drinking 8-10 glasses of water daily",
            "Eat small, frequent meals to help with nausea",
            "Include a variety of colorful fruits and vegetables",
            "Choose whole grains over refined grains",
            "Limit caffeine to 200mg per day"
        ],
        "supplements": [
            {"name": "Prenatal Vitamin", "dosage": "1 tablet daily", "reason": "Comprehensive nutrition support"},
            {"name": "Folic Acid", "dosage": "400-800 mcg", "reason": "Prevents neural tube defects"},
            {"name": "Iron", "dosage": "27 mg daily", "reason": "Prevents anemia"}
        ]
    }
# Update the existing diet_plan endpoint to use structured format as well
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

        # Generate structured diet plan
        diet_plan = generate_structured_diet_plan(
            data['trimester'],
            data['weight'],
            data['health_conditions'],
            data['dietary_preference']
        )

        # --- Optionally save to DB ---
        supabase.table('diet_plans').insert({
            'UID': user_data.user.id,
            'diet_plan': str(diet_plan)  # Convert to string for storage
        }).execute()

        return jsonify({"diet_plan": diet_plan})

    except Exception as e:
        print(e)
        return jsonify({"error": str(e)}), 500

@app.route('/')
def ind():
    return "Hello governer"

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)