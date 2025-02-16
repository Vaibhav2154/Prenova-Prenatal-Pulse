import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prenova/features/auth/auth_service.dart';

class PregnancyChatScreen extends StatefulWidget {
  @override
  _PregnancyChatScreenState createState() => _PregnancyChatScreenState();
}

class _PregnancyChatScreenState extends State<PregnancyChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    fetchChatHistory();
  }

  Future<void> fetchChatHistory() async {
    final session = _authService.currentSession;
    final token = session?.accessToken;
    final response = await http.get(Uri.parse("http://localhost:5003/chat"),headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> history = jsonDecode(response.body);
      setState(() {
        messages = history
            .map((e) => {
                  "role": e["role"],
                  "content": e["content"].replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), ''),
                })
            .toList();
      });
    }
  }

  void sendMessage(String userMessage) async {
    final session = _authService.currentSession;
    final token = session?.accessToken;
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": userMessage});
      _controller.clear();
    });

    final response = await http.post(
      Uri.parse("http://localhost:5003/chat"),
      headers: {"Content-Type": "application/json",'Authorization':'Bearer $token'},
      body: jsonEncode({"message": userMessage.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')}),
    );
    fetchChatHistory();
    // if (response.statusCode == 200) {
    //   final responseData = jsonDecode(response.body);
    //   String botResponse = responseData['content'];
    //   print(response.body);
    //   setState(() {
    //     messages.add({"role": "bot", "content": botResponse.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')});
    //   });
    // } else {
    //   setState(() {
    //     messages.add({"role": "bot", "content": "Error: unable to fetch response."});
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prenova AI Assistant"),
        backgroundColor: AppPallete.gradient1,
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
                      color: isUser
                          ? AppPallete.gradient1
                          : Color.fromARGB(255, 49, 48, 48),
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
                                backgroundColor: AppPallete.gradient1,
                                child: Icon(Icons.health_and_safety,
                                    color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Text("Prenova",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 5),
                        ],
                        if (message["content"] != null)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              message["content"],
                              style: TextStyle(fontSize: 16, color: isUser ? Colors.black : Colors.white),
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
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask about pregnancy health...",
                      hintStyle: TextStyle(color: AppPallete.borderColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(color: AppPallete.secondaryFgColor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppPallete.gradient1, size: 30),
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
