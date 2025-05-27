from fastapi import FastAPI, HTTPException, Request, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from dotenv import load_dotenv
import os
import joblib
import numpy as np
import google.generativeai as genai
from supabase import create_client, Client
import uvicorn

# Load environment variables
load_dotenv()

app = FastAPI()

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase & Gemini setup
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
OLLAMA_MODEL_ID = os.getenv("OLLAMA_MODEL_ID")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing Supabase credentials")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Models and scalers
maternal_model = joblib.load("finalized_maternal_model.sav")
maternal_scaler = joblib.load("scaleX.pkl")
fetal_model = joblib.load("fetal_health_model.sav")
fetal_scaler = joblib.load("scaleX1.pkl")

# Gemini model
genai.configure(api_key=GEMINI_API_KEY)
chatmodel = genai.GenerativeModel("gemini-2.0-flash")

# --- Schemas ---
class DoctorProfile(BaseModel):
    name: str
    phone: str
    specialty: str
    location: str
    profile_image_url: str

class MaternalVitals(BaseModel):
    age: float
    systolic_bp: float
    diastolic_bp: float
    blood_glucose: float
    body_temp: float
    heart_rate: float

class FetalFeatures(BaseModel):
    features: List[float]

class DietRequest(BaseModel):
    trimester: str
    weight: float
    health_conditions: str
    dietary_preference: str

# --- Utility ---
def verify_token(auth_header: str) -> str:
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No valid token provided")
    token = auth_header.split(" ")[1]
    user_data = supabase.auth.get_user(token)
    if not user_data or not user_data.user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_data.user.id

# --- Endpoints ---

@app.post("/create_doctor_profile")
def create_doctor_profile(data: DoctorProfile):
    result = supabase.table('doctors').upsert(data.dict()).execute()
    return {"message": "Doctor profile created successfully", "data": result.data}

@app.post("/predict_maternal")
def predict_maternal(vitals: MaternalVitals, authorization: str = Header(...)):
    user_id = verify_token(authorization)
    features = np.array([
        vitals.age, vitals.systolic_bp, vitals.diastolic_bp,
        vitals.blood_glucose, vitals.body_temp, vitals.heart_rate
    ]).reshape(1, -1)
    scaled = maternal_scaler.transform(features)
    prediction = maternal_model.predict(scaled)[0]
    risk_map = {0: "Normal", 1: "Suspect", 2: "Pathological"}
    risk_level = risk_map.get(int(prediction), "Unknown")

    supabase.table('vitals').insert({
        'UID': user_id,
        **vitals.dict(),
        'prediction': int(prediction)
    }).execute()

    return {"prediction": risk_level}

@app.post("/predict_fetal")
def predict_fetal(data: FetalFeatures, authorization: str = Header(...)):
    user_id = verify_token(authorization)
    if len(data.features) != 15:
        raise HTTPException(status_code=400, detail="Invalid feature length, expected 15")

    features = np.array(data.features).reshape(1, -1)
    scaled = fetal_scaler.transform(features)
    prediction = int(fetal_model.predict(scaled)[0])

    health_status = {1: "Normal", 2: "Suspect", 3: "Pathological"}
    prediction_result = health_status.get(prediction, "Unknown")

    feature_names = [
        'baseline_value', 'accelerations', 'fetal_movement', 'uterine_contractions',
        'light_decelerations', 'severe_decelerations', 'prolonged_decelerations',
        'abnormal_short_term_variability', 'mean_value_of_short_term_variability',
        'percentage_of_time_with_abnormal_long_term_variability', 'mean_value_of_long_term_variability',
        'histogram_width', 'histogram_min', 'histogram_max', 'histogram_number_of_peaks'
    ]

    record = dict(zip(feature_names, map(float, data.features)))
    record['UID'] = user_id
    record['prediction'] = prediction

    supabase.table('ctg').insert(record).execute()

    return {"prediction": prediction, "status": prediction_result}

@app.post("/diet_plan")
def pregnancy_diet(req: DietRequest, authorization: str = Header(...)):
    user_id = verify_token(authorization)
    prompt = (
        f"You are a professional dietician and nutritionist. Suggest safe and personalized diet plans for pregnant women.\n"
        f"Now, generate a diet plan for a woman in her {req.trimester} trimester, weighing {req.weight} kg,\n"
        f"who is feeling {req.health_conditions} and follows these dietary preferences: {req.dietary_preference}.\n"
        f"Give two separate diet plans: one vegetarian and one non-vegetarian.\n"
        f"Do not include anything that violates her preferences.\n"
        f"Present the results clearly in markdown format with headings and bullet points."
    )

    response = chatmodel.generate_content({"role": "user", "parts": [{"text": prompt}]})
    diet_plan_text = response.text

    supabase.table('diet_plans').insert({
        'UID': user_id,
        'diet_plan': diet_plan_text
    }).execute()

    return {"diet_plan": diet_plan_text}

# Run with: uvicorn filename:app --reload
if __name__ == "__main__":
    uvicorn.run("filename:app", host="0.0.0.0", port=8000, reload=True)
