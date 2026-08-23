import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "sender": "ai",
      "text": "Hello! I'm your DermaSense AI Assistant. How can I help you with your skin health today?"
    }
  ];
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      systemInstruction: Content.system('You are the DermaSense AI Assistant, a helpful and knowledgeable assistant integrated into a skin health mobile app. Provide concise, friendly, and practical advice about skincare, routines, and products. Always remind users that you provide AI-assisted guidance, and for clinical concerns they should consult a dermatologist.'),
      generationConfig: GenerationConfig(
        maxOutputTokens: 300,
      ),
    );
    _chat = _model.startChat();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final query = _controller.text;
    setState(() {
      _messages.add({"sender": "user", "text": query});
      _messages.add({"sender": "ai", "text": ""});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final responseStream = _chat.sendMessageStream(Content.text(query));
      
      await for (final chunk in responseStream) {
        if (chunk.text != null && mounted) {
          setState(() {
            _messages.last["text"] = (_messages.last["text"]! + chunk.text!).replaceAll(RegExp(r'\n{3,}'), '\n\n');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_messages.last["text"]!.isEmpty) {
            _messages.last["text"] = "I'm sorry, I encountered an error: $e";
          } else {
            _messages.add({
              "sender": "ai",
              "text": "I'm sorry, I encountered an error: $e"
            });
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _messages.last["text"] = _messages.last["text"]!.trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: (!isUser && msg["text"]!.isEmpty && _isLoading)
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : MarkdownBody(
                            data: msg["text"]!,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              h1: TextStyle(color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                              h2: TextStyle(color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                              h3: TextStyle(color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                              listBullet: TextStyle(color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface),
                              code: TextStyle(
                                backgroundColor: isUser ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask about your skin...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
