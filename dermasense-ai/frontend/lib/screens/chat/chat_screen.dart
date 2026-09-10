import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _streamUpdateTimer;
  String _pendingAiText = '';

  final List<String> _suggestedPrompts = [
    "What's a good morning routine?",
    "How to treat acne scars?",
    "Best ingredients for hydration?",
  ];

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _flushPendingAiText() {
    if (_pendingAiText.isEmpty || !mounted || _messages.isEmpty) return;
    final pendingText = _pendingAiText;
    _pendingAiText = '';
    setState(() {
      _messages.last['text'] = (_messages.last['text']! + pendingText).replaceAll(RegExp(r'\n{3,}'), '\n\n');
    });
    _scrollToBottom();
  }

  void _queueAiText(String text) {
    _pendingAiText += text;
    _streamUpdateTimer ??= Timer(const Duration(milliseconds: 50), () {
      _streamUpdateTimer = null;
      _flushPendingAiText();
    });
  }

  void _sendMessage(String query) async {
    if (query.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add({"sender": "user", "text": query});
      _messages.add({"sender": "ai", "text": ""});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final history = _messages.length > 2
          ? _messages.sublist(0, _messages.length - 2).map((m) => {
                'sender': m['sender'] ?? 'user',
                'text': m['text'] ?? '',
              }).toList()
          : <Map<String, String>>[];

      final responseStream = AiService().generateChatStream(
        prompt: query,
        systemInstruction: 'You are the DermaSense AI Assistant. Provide concise, friendly skincare advice.',
        conversationHistory: history,
      );

      await for (final chunk in responseStream) {
        if (mounted) {
          _queueAiText(chunk);
        }
      }
      _streamUpdateTimer?.cancel();
      _streamUpdateTimer = null;
      _flushPendingAiText();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.last["text"] = "Error: $e";
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
  void dispose() {
    _streamUpdateTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("AI Assistant")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: AppTheme.space24),
            Text("How can I help your skin today?", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppTheme.space40),
            Wrap(
              spacing: AppTheme.space12,
              runSpacing: AppTheme.space12,
              alignment: WrapAlignment.center,
              children: _suggestedPrompts.map((prompt) => _buildPromptChip(prompt)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return InkWell(
      onTap: () => _sendMessage(prompt),
      borderRadius: AppTheme.borderRadiusPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: AppTheme.borderRadiusPill,
          border: Border.all(color: AppTheme.surfaceHighlight),
        ),
        child: Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.space16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg["sender"] == "user";
        return _buildChatBubble(msg["text"]!, isUser);
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space16),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surfaceElevated,
          borderRadius: AppTheme.borderRadiusLarge.copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(AppTheme.radiusLarge),
            bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: (!isUser && text.isEmpty && _isLoading)
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
              )
            : MarkdownBody(
                data: text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.5),
                  listBullet: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary),
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space8, AppTheme.space16, AppTheme.space16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: AppTheme.borderRadiusPill,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Ask me anything...",
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textDisabled),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                ),
                onSubmitted: (val) => _sendMessage(val),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
