import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:prenova/core/constants/api_contants.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/core/utils/loader.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prenova/features/auth/auth_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PregnancyChatScreen extends StatefulWidget {
  final String? sessionId;
  
  const PregnancyChatScreen({Key? key, this.sessionId}) : super(key: key);

  @override
  _PregnancyChatScreenState createState() => _PregnancyChatScreenState();
}

class _PregnancyChatScreenState extends State<PregnancyChatScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> chatSessions = [];
  String? currentSessionId;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isInitializing = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  // Voice features
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _initializeSpeech();
    _initializeChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _speechEnabled = await _speech.initialize();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _initializeChat() async {
    await fetchChatSessions();
    if (widget.sessionId != null) {
      await loadChatSession(widget.sessionId!);
    } else if (chatSessions.isNotEmpty) {
      await loadChatSession(chatSessions.first['id']);
    }
    setState(() {
      _isInitializing = false;
    });
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> fetchChatSessions() async {
    try {
      final session = _authService.currentSession;
      final token = session?.accessToken;
      
      final response = await http.get(
        Uri.parse("${ApiContants.baseUrl}/chat/sessions"),
        headers: {"Authorization": "Bearer $token"}
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> sessions = jsonDecode(response.body);
        setState(() {
          chatSessions = sessions.map((e) => {
            "id": e["id"],
            "title": e["title"] ?? "New Chat",
            "created_at": e["created_at"],
            "updated_at": e["updated_at"],
          }).toList();
        });
      }
    } catch (e) {
      log('Error fetching chat sessions: $e');
    }
  }

  Future<void> loadChatSession(String sessionId) async {
    final session = _authService.currentSession;
    final token = session?.accessToken;
    
    setState(() {
      _isLoading = true;
      currentSessionId = sessionId;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiContants.baseUrl}/chat/sessions/$sessionId"),
        headers: {"Authorization": "Bearer $token"}
      );
      
      if (response.statusCode == 200) {
        final sessionData = jsonDecode(response.body);
        setState(() {
          messages = (sessionData["messages"] as List<dynamic>)
              .where((e) => e["role"] != "system") // Filter out system messages
              .map((e) => {
                    "role": e["role"],
                    "content": e["content"].toString().replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), ''),
                  })
              .toList();
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading chat session: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> createNewSession() async {
    final session = _authService.currentSession;
    final token = session?.accessToken;
    
    try {
      final response = await http.post(
        Uri.parse("${ApiContants.baseUrl}/chat/sessions"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );
      
      if (response.statusCode == 201) {
        final newSession = jsonDecode(response.body);
        setState(() {
          messages = [];
          currentSessionId = newSession['id'];
        });
        await fetchChatSessions();
      }
    } catch (e) {
      log('Error creating session: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final session = _authService.currentSession;
    final token = session?.accessToken;
    
    try {
      final response = await http.delete(
        Uri.parse("${ApiContants.baseUrl}/chat/sessions/$sessionId"),
        headers: {"Authorization": "Bearer $token"}
      );
      
      if (response.statusCode == 200) {
        await fetchChatSessions();
        if (currentSessionId == sessionId) {
          setState(() {
            messages = [];
            currentSessionId = null;
          });
          if (chatSessions.isNotEmpty) {
            await loadChatSession(chatSessions.first['id']);
          }
        }
      }
    } catch (e) {
      log('Error deleting session: $e');
    }
  }

  void sendMessage(String userMessage) async {
    final session = _authService.currentSession;
    final token = session?.accessToken;
    if (userMessage.trim().isEmpty) return;

    // Stop any ongoing TTS
    await _flutterTts.stop();

    if (currentSessionId == null) {
      await createNewSession();
      if (currentSessionId == null) {
        _showErrorSnackBar("Unable to create chat session");
        return;
      }
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      messages.add({"role": "user", "content": userMessage.trim()});
      _controller.clear();
      _isLoading = true;
    });
    
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("${ApiContants.baseUrl}/chat/sessions/$currentSessionId/message"),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          "message": userMessage.trim().replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String botResponse = responseData['content'];
        setState(() {
          messages.add({
            "role": "assistant", 
            "content": botResponse.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
          });
        });
        _scrollToBottom();
        await fetchChatSessions();
      } else {
        setState(() {
          messages.add({"role": "assistant", "content": "I'm having trouble responding right now. Please try again."});
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        messages.add({"role": "assistant", "content": "Connection error. Please check your internet and try again."});
      });
      log('Error sending message: $e');
    }
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getCurrentSessionTitle() {
    if (currentSessionId == null) return "New Chat";
    final session = chatSessions.firstWhere(
      (s) => s['id'] == currentSessionId,
      orElse: () => {'title': 'New Chat'}
    );
    return session['title'] ?? 'New Chat';
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppPallete.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomLoader(
                size: 60,
                color: AppPallete.gradient1,
              ),
              SizedBox(height: 24),
              Text(
                "Initializing Prenova...",
                style: TextStyle(
                  color: AppPallete.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPallete.backgroundColor,
              AppPallete.gradient1.withOpacity(0.03),
              AppPallete.backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessagesList()),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: FadeTransition(
        opacity: _fadeController,
        child: Column(
          children: [
            Text(
              'NOVA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Nurturing Online Virtual A",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPallete.gradient1, AppPallete.gradient2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: AppPallete.gradient1.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.moreVertical, color: Colors.white, size: 20),
          ),
          onSelected: (value) {
            switch (value) {
              case 'new_chat':
                createNewSession();
                break;
              case 'chat_history':
                _showChatHistoryBottomSheet();
                break;
              case 'clear_current':
                _clearCurrentChat();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new_chat',
              child: Row(
                children: [
                  Icon(LucideIcons.plus, size: 18),
                  SizedBox(width: 12),
                  Text('New Chat'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'chat_history',
              child: Row(
                children: [
                  Icon(LucideIcons.history, size: 18),
                  SizedBox(width: 12),
                  Text('Chat History'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear_current',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Clear Chat', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (messages.isEmpty && !_isLoading) {
      return _buildWelcomeScreen();
    }

    return FadeTransition(
      opacity: _fadeController,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && _isLoading) {
            return _buildTypingIndicator();
          }

          final message = messages[index];
          final bool isUser = message["role"] == "user";
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isUser ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutBack,
            )),
            child: _buildMessageBubble(message, isUser),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return FadeTransition(
      opacity: _fadeController,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.gradient1, AppPallete.gradient2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.gradient1.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.health_and_safety,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Welcome to Nova!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.gradient1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                "Nurturing Online Virtual Assistant",
                style: TextStyle(
                  fontSize: 16,
                  color: AppPallete.gradient1,
                  height: 1.5,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                "Your AI pregnancy companion is here to support you throughout your journey. Ask me anything about pregnancy health, symptoms, or general wellness!",
                style: TextStyle(
                  fontSize: 16,
                  color: AppPallete.textColor.withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              _buildSuggestedQuestions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    final suggestions = [
      "What should I eat during pregnancy?",
      "How can I manage morning sickness?",
      "What exercises are safe for me?",
      "Tell me about fetal development",
    ];

    return Column(
      children: [
        Text(
          "Try asking:",
          style: TextStyle(
            fontSize: 14,
            color: AppPallete.textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) => GestureDetector(
            onTap: () => sendMessage(suggestion),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppPallete.gradient1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppPallete.gradient1.withOpacity(0.3),
                ),
              ),
              child: Text(
                suggestion,
                style: TextStyle(
                  color: AppPallete.gradient1,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPallete.gradient1,
              child: Icon(Icons.health_and_safety, color: Colors.white, size: 18),
            ),
            SizedBox(width: 12),
            CustomLoader(
              size: 20,
              color: AppPallete.gradient1,
            ),
            SizedBox(width: 12),
            Text(
              "Prenova is thinking...",
              style: TextStyle(
                color: AppPallete.textColor.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppPallete.gradient1 : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? Radius.circular(6) : Radius.circular(20),
            bottomLeft: isUser ? Radius.circular(20) : Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppPallete.gradient1,
                    child: Icon(Icons.health_and_safety, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Prenova",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppPallete.gradient1,
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () => _speak(message["content"]),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppPallete.gradient1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.volume2,
                        size: 16,
                        color: AppPallete.gradient1,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
            if (message["content"] != null)
              isUser 
                ? Text(
                    message["content"],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: message["content"],
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 16,
                        color: AppPallete.textColor,
                        height: 1.4,
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.gradient1,
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.gradient1,
                      ),
                      h3: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.gradient1,
                      ),
                      listBullet: TextStyle(color: AppPallete.textColor),
                      strong: TextStyle(
                        color: AppPallete.gradient1,
                        fontWeight: FontWeight.bold,
                      ),
                      code: TextStyle(
                        backgroundColor: AppPallete.gradient1.withOpacity(0.1),
                        color: AppPallete.gradient1,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppPallete.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppPallete.borderColor.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Ask Prenova about your pregnancy...",
                    hintStyle: TextStyle(
                      color: AppPallete.borderColor.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: AppPallete.textColor,
                    fontSize: 16,
                  ),
                  onSubmitted: (text) => sendMessage(text.trim()),
                ),
              ),
            ),
            SizedBox(width: 12),
            if (_speechEnabled)
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isListening 
                        ? AppPallete.gradient2.withOpacity(0.9)
                        : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : AppPallete.gradient2)
                            .withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? LucideIcons.mic : LucideIcons.micOff,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => sendMessage(_controller.text.trim()),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.gradient1, AppPallete.gradient2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.gradient1.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCurrentChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Chat'),
        content: Text('Are you sure you want to clear this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                messages.clear();
              });
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChatHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.gradient1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.plus, color: AppPallete.gradient1),
                    onPressed: () {
                      Navigator.pop(context);
                      createNewSession();
                    },
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[200]),
            Expanded(
              child: chatSessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.messageSquare,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No chat sessions found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: chatSessions.length,
                      itemBuilder: (context, index) {
                        final session = chatSessions[index];
                        final isCurrentSession = session['id'] == currentSessionId;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCurrentSession 
                                ? AppPallete.gradient1.withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentSession 
                                  ? AppPallete.gradient1.withOpacity(0.3)
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrentSession 
                                    ? AppPallete.gradient1 
                                    : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.messageSquare,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              session['title'] ?? 'New Chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppPallete.textColor,
                              ),
                            ),
                            subtitle: Text(
                              _formatDate(session['updated_at']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                LucideIcons.trash2,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              onPressed: () => _confirmDeleteSession(session['id']),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              loadChatSession(session['id']);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSession(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              deleteSession(sessionId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}