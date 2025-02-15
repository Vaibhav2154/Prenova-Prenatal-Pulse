
import numpy as np
from flask import Flask, request, jsonify
import joblib
# Load the trained model and scaler
model_path = "fetal_health_model.sav"
scaler_path = "scaleX1.pkl"

with open(model_path, "rb") as model_file:
    model = joblib.load(model_file)

with open(scaler_path, "rb") as scaler_file:
    scaler = joblib.load(scaler_file)
    print("Scaler expects feature count:", scaler.n_features_in_)

# Initialize Flask app
app = Flask(__name__)

@app.route('/')
def home():
    return "Fetal Health Prediction API is running. Use /predict to get predictions."

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        features = np.array(data["features"]).reshape(1, -1)
        
        # Scale the input features
        scaled_features = scaler.transform(features)

        # Make a prediction
        prediction = model.predict(scaled_features)[0]
        
        # Map prediction to health status
        health_status = {1: "Normal", 2: "Suspect", 3: "Pathological"}
        result = {"prediction": int(prediction), "status": health_status.get(int(prediction), "Unknown")}
        
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == '__main__':
    app.run(debug=True)
