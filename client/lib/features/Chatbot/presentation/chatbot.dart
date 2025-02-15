import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'gemini_service.dart';

class PregnancyChatScreen extends StatefulWidget {
  @override
  _PregnancyChatScreenState createState() => _PregnancyChatScreenState();
}

class _PregnancyChatScreenState extends State<PregnancyChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService geminiService = GeminiService();
  List<Map<String, dynamic>> messages = [];
  File? _selectedImage;
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _voiceInput = "";

  @override
  void initState() {
    super.initState();
    _speech.initialize();
  }

  void sendMessage(String userMessage) async {
    if (userMessage.isEmpty && _selectedImage == null) return;

    setState(() {
      messages.add({"role": "user", "text": userMessage, "image": _selectedImage});
      _controller.clear();
      _selectedImage = null;
    });

    String botResponse = await geminiService.sendMessage(userMessage);

    setState(() {
      messages.add({"role": "bot", "text": botResponse});
    });

    _speak(botResponse);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _voiceInput = result.recognizedWords;
          });
        });
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      sendMessage(_voiceInput);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prenova AI Assistant"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 6,
        shadowColor: Colors.black38,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final bool isUser = message["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.pinkAccent : Color.fromARGB(255, 49, 48, 48),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: Offset(2, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.pinkAccent,
                                child: Icon(Icons.health_and_safety, color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Text("Prenova", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 5),
                        ],
                        if (message["image"] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              message["image"],
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (message["text"] != null)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              message["text"],
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.mic, color: _isListening ? Colors.red : Colors.pinkAccent, size: 30),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: Icon(Icons.image, color: Colors.pinkAccent, size: 30),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about pregnancy health...",
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.pinkAccent, size: 30),
                  onPressed: () => sendMessage(_controller.text.trim()),
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }
}
