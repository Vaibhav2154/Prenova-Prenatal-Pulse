from flask import Flask, request, jsonify
from flask_cors import CORS
import ollama
import PyPDF2
import io

app = Flask(__name__)
CORS(app)  # Allow CORS for Flutter frontend

def extract_text_from_pdf(pdf_bytes):
    """Extracts text from a PDF file."""
    pdf_reader = PyPDF2.PdfReader(io.BytesIO(pdf_bytes))
    text = ''
    for page in pdf_reader.pages:
        text += page.extract_text() + "\n"
    return text

@app.route('/analyze-ctg', methods=['POST'])
def analyze_ctg():
    """Handles CTG PDF analysis."""
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    pdf_bytes = file.read()
    extracted_text = extract_text_from_pdf(pdf_bytes)

    # Send extracted text to Ollama DeepSeek R1
    response = ollama.chat(model="deepseek-r1", messages=[
        {"role": "user", "content": f"Analyze this CTG report and provide insights: {extracted_text}"}
    ])

    return jsonify({"analysis": response['message']['content']})


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
