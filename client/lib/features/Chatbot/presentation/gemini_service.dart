import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyC5I3IvJ_QnEsb28ncuwRgauLCwFLtp6pk";  
  final String model = "gemini-2.0-flash";  

  Future<String> sendMessage(String message) async {
    const String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";

    try {
      final response = await http.post(
        Uri.parse("$url?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "You are Prenova Bot, a warm and supportive Pregnancy Health AI Assistant for expecting mothers. Your role is to provide emotional support, mindfulness guidance, and reassurance throughout pregnancy. Begin each response with an uplifting quote related to motherhood, self-care, or resilience. Keep responses short, nurturing, and comforting, using emojis to add warmth 🤰💖. If the user asks for a detailed response, provide a deeper, more thoughtful answer. Always be empathetic, encouraging, and non-judgmental, creating a safe space for expecting parents to express their feelings"},
                {"text": message}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        return "Error: ${response.body}";
      }
    } catch (e) {
      return "Failed to connect to API: $e";
    }
  }
}
