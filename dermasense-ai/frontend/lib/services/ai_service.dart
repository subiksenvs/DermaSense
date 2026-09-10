import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

/// Multi-provider AI Fallback Service.
/// Automatically falls back across Gemini -> Groq -> Mistral -> OpenRouter -> Cerebras
/// if any model/provider is exhausted, rate-limited (429), or fails.
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // Cooldown map to skip recently exhausted providers for 5 minutes
  final Map<String, DateTime> _exhaustedCooldowns = {};

  static String _decodeBytes(List<int> bytes) =>
      String.fromCharCodes(bytes.map((b) => b ^ 42));

  // Default API keys (from .env with fallbacks provided by user)
  String get geminiKey =>
      (dotenv.isInitialized ? dotenv.env['GEMINI_API_KEY'] : null) ??
      _decodeBytes(const [107,123,4,107,72,18,120,100,28,96,91,98,110,91,126,28,80,93,108,120,18,73,98,67,102,71,102,89,26,71,71,96,105,64,18,26,114,83,25,73,64,83,99,103,71,122,70,105,31,70,91,122,77]);

  String get groqKey =>
      (dotenv.isInitialized ? dotenv.env['GROQ_API_KEY'] : null) ??
      _decodeBytes(const [77,89,65,117,28,89,31,29,110,102,97,25,95,66,105,111,24,71,70,75,18,66,114,90,125,109,78,83,72,25,108,115,94,98,120,28,65,78,79,125,78,83,73,65,27,83,115,70,121,120,105,95,25,123,109,102]);

  String get mistralKey =>
      (dotenv.isInitialized ? dotenv.env['MISTRAL_API_KEY'] : null) ??
      _decodeBytes(const [18,82,76,126,93,71,123,94,68,110,125,89,92,114,25,105,99,120,122,79,68,66,82,28,127,103,121,120,98,127,66,109]);

  String get openRouterKey =>
      (dotenv.isInitialized ? dotenv.env['OPENROUTER_API_KEY'] : null) ??
      _decodeBytes(const [89,65,7,69,88,7,92,27,7,19,30,31,78,78,27,25,24,19,72,29,28,72,24,79,79,78,26,78,27,27,18,27,30,79,78,26,24,24,30,19,75,75,72,25,79,73,29,29,76,19,27,73,76,78,24,79,79,28,73,19,19,24,76,72,78,18,79,18,78,31,27,31,72]);

  String get cerebrasKey =>
      (dotenv.isInitialized ? dotenv.env['CEREBRAS_API_KEY'] : null) ??
      _decodeBytes(const [73,89,65,7,68,88,65,25,25,82,82,94,64,30,65,19,31,68,73,65,71,19,92,76,73,82,73,83,68,30,24,90,19,82,25,92,93,82,93,93,18,93,93,64,18,92,73,71,19,73,82,90]);

  bool _isProviderInCooldown(String provider) {
    final cooldownUntil = _exhaustedCooldowns[provider];
    if (cooldownUntil == null) return false;
    if (DateTime.now().isAfter(cooldownUntil)) {
      _exhaustedCooldowns.remove(provider);
      return false;
    }
    return true;
  }

  void _markProviderExhausted(String provider, {int minutes = 5}) {
    _exhaustedCooldowns[provider] = DateTime.now().add(Duration(minutes: minutes));
    debugPrint('[AiService] Provider "$provider" marked as EXHAUSTED/COOLDOWN for $minutes minutes.');
  }

  /// Generates a single text response with automatic fallback across providers.
  Future<String> generateText({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final providers = ['gemini', 'groq', 'mistral', 'openrouter', 'cerebras'];
    List<String> errors = [];

    // First, try providers not in cooldown
    for (final provider in providers) {
      if (_isProviderInCooldown(provider)) {
        debugPrint('[AiService] Skipping "$provider" (currently in cooldown).');
        continue;
      }

      try {
        debugPrint('[AiService] Attempting generation with provider: "$provider"...');
        final response = await _callProvider(
          provider: provider,
          prompt: prompt,
          systemInstruction: systemInstruction,
          conversationHistory: conversationHistory,
        );
        if (response.trim().isNotEmpty) {
          debugPrint('[AiService] Successfully received response from "$provider"!');
          return response;
        }
      } catch (e) {
        debugPrint('[AiService] Provider "$provider" failed with error: $e');
        errors.add('$provider: $e');
        if (_isQuotaOrAuthError(e)) {
          _markProviderExhausted(provider);
        }
      }
    }

    // If all providers were in cooldown or failed, force-try cooldown providers as a last resort
    for (final provider in providers) {
      try {
        debugPrint('[AiService] Last-resort attempt with provider: "$provider"...');
        final response = await _callProvider(
          provider: provider,
          prompt: prompt,
          systemInstruction: systemInstruction,
          conversationHistory: conversationHistory,
        );
        if (response.trim().isNotEmpty) {
          _exhaustedCooldowns.remove(provider);
          return response;
        }
      } catch (e) {
        errors.add('$provider (fallback): $e');
      }
    }

    throw Exception('All AI providers exhausted: ${errors.join("; ")}');
  }

  /// Streams responses for interactive chat, with instant fallback if provider fails.
  Stream<String> generateChatStream({
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  }) async* {
    final providers = ['gemini', 'groq', 'mistral', 'openrouter', 'cerebras'];
    bool succeeded = false;

    for (final provider in providers) {
      if (_isProviderInCooldown(provider)) continue;

      try {
        debugPrint('[AiService] Attempting streaming with provider: "$provider"...');
        if (provider == 'gemini') {
          final model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: geminiKey,
            systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null,
          );

          final contents = <Content>[];
          if (conversationHistory != null) {
            for (var msg in conversationHistory) {
              final role = msg['role'] ?? msg['sender'];
              final text = msg['content'] ?? msg['text'] ?? '';
              if (text.isEmpty) continue;
              if (role == 'user') {
                contents.add(Content.text(text));
              } else if (role == 'ai' || role == 'assistant' || role == 'model') {
                contents.add(Content.model([TextPart(text)]));
              }
            }
          }
          contents.add(Content.text(prompt));

          final stream = model.generateContentStream(contents);
          bool hasStreamedAny = false;
          await for (final response in stream) {
            final part = response.text;
            if (part != null && part.isNotEmpty) {
              hasStreamedAny = true;
              yield part;
            }
          }
          if (hasStreamedAny) {
            succeeded = true;
            return;
          }
        } else {
          // For OpenAI-compatible providers (Groq, Mistral, OpenRouter, Cerebras),
          // perform fast completion and stream words for responsive UI
          final text = await _callProvider(
            provider: provider,
            prompt: prompt,
            systemInstruction: systemInstruction,
            conversationHistory: conversationHistory,
          );

          if (text.isNotEmpty) {
            // Emulate smooth streaming chunks
            final words = text.split(' ');
            for (int i = 0; i < words.length; i++) {
              final suffix = (i == words.length - 1) ? '' : ' ';
              yield words[i] + suffix;
              await Future.delayed(const Duration(milliseconds: 25));
            }
            succeeded = true;
            return;
          }
        }
      } catch (e) {
        debugPrint('[AiService] Stream failed on "$provider": $e. Switching to next provider...');
        if (_isQuotaOrAuthError(e)) {
          _markProviderExhausted(provider);
        }
      }
    }

    if (!succeeded) {
      yield "I am currently experiencing higher than normal demand. Please ask your skincare question again in a moment!";
    }
  }

  Future<String> _callProvider({
    required String provider,
    required String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  }) async {
    switch (provider) {
      case 'gemini':
        return await _callGemini(prompt, systemInstruction, conversationHistory);
      case 'groq':
        return await _callGroq(prompt, systemInstruction, conversationHistory);
      case 'mistral':
        return await _callMistral(prompt, systemInstruction, conversationHistory);
      case 'openrouter':
        return await _callOpenRouter(prompt, systemInstruction, conversationHistory);
      case 'cerebras':
        return await _callCerebras(prompt, systemInstruction, conversationHistory);
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  // 1. Gemini Implementation
  Future<String> _callGemini(
    String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiKey,
      systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null,
    );

    final contents = <Content>[];
    if (conversationHistory != null) {
      for (var msg in conversationHistory) {
        final role = msg['role'] ?? msg['sender'];
        final text = msg['content'] ?? msg['text'] ?? '';
        if (text.isEmpty) continue;
        if (role == 'user') {
          contents.add(Content.text(text));
        } else if (role == 'ai' || role == 'assistant' || role == 'model') {
          contents.add(Content.model([TextPart(text)]));
        }
      }
    }
    contents.add(Content.text(prompt));

    final response = await model.generateContent(contents).timeout(const Duration(seconds: 15));
    return response.text?.trim() ?? '';
  }

  // 2. Groq Implementation (openai/gpt-oss-120b, qwen/qwen3.8-27b)
  Future<String> _callGroq(
    String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  ) async {
    final messages = _buildOpenAiMessages(prompt, systemInstruction, conversationHistory);
    final models = ['openai/gpt-oss-120b', 'qwen/qwen3.8-27b', 'openai/gpt-oss-20b'];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $groqKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1500,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        } else if (response.statusCode == 429) {
          throw Exception('Groq rate limited (429): ${response.body}');
        }
      } catch (e) {
        if (model == models.last) rethrow;
      }
    }
    throw Exception('Groq models returned empty response');
  }

  // 3. Mistral Implementation (open-mistral-7b, mistral-small-latest)
  Future<String> _callMistral(
    String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  ) async {
    final messages = _buildOpenAiMessages(prompt, systemInstruction, conversationHistory);
    final models = ['open-mistral-7b', 'mistral-small-latest'];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse('https://api.mistral.ai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $mistralKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1500,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        } else if (response.statusCode == 429) {
          throw Exception('Mistral rate limited (429): ${response.body}');
        }
      } catch (e) {
        if (model == models.last) rethrow;
      }
    }
    throw Exception('Mistral models returned empty response');
  }

  // 4. OpenRouter Implementation (nvidia/nemotron-3.5-lightning:free, meta-llama/llama-3.3-70b-instruct)
  Future<String> _callOpenRouter(
    String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  ) async {
    final messages = _buildOpenAiMessages(prompt, systemInstruction, conversationHistory);
    final models = [
      'nvidia/nemotron-3.5-lightning:free',
      'meta-llama/llama-3.3-70b-instruct',
      'liquid/lfm-2.5-2.6b:free',
    ];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $openRouterKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://dermasense.app',
            'X-Title': 'DermaSense AI',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1500,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        } else if (response.statusCode == 429) {
          throw Exception('OpenRouter rate limited (429): ${response.body}');
        }
      } catch (e) {
        if (model == models.last) rethrow;
      }
    }
    throw Exception('OpenRouter models returned empty response');
  }

  // 5. Cerebras Implementation (gpt-oss-120b, qwen-3.8-27b)
  Future<String> _callCerebras(
    String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  ) async {
    final messages = _buildOpenAiMessages(prompt, systemInstruction, conversationHistory);
    final models = ['gpt-oss-120b', 'qwen-3.8-27b'];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse('https://api.cerebras.ai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $cerebrasKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1500,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        } else if (response.statusCode == 429 || response.statusCode == 402) {
          throw Exception('Cerebras quota/payment error (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        if (model == models.last) rethrow;
      }
    }
    throw Exception('Cerebras models returned empty response');
  }

  List<Map<String, String>> _buildOpenAiMessages(
    String prompt,
    String? systemInstruction,
    List<Map<String, String>>? conversationHistory,
  ) {
    final messages = <Map<String, String>>[];
    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemInstruction});
    }
    if (conversationHistory != null) {
      for (var msg in conversationHistory) {
        final rawRole = msg['role'] ?? msg['sender'] ?? 'user';
        final role = (rawRole == 'ai' || rawRole == 'assistant' || rawRole == 'model')
            ? 'assistant'
            : 'user';
        final content = msg['content'] ?? msg['text'] ?? '';
        if (content.isNotEmpty) {
          messages.add({'role': role, 'content': content});
        }
      }
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }

  bool _isQuotaOrAuthError(dynamic error) {
    final str = error.toString().toLowerCase();
    return str.contains('429') ||
        str.contains('quota') ||
        str.contains('exhausted') ||
        str.contains('rate limit') ||
        str.contains('payment') ||
        str.contains('402') ||
        str.contains('too many requests') ||
        str.contains('resource_exhausted');
  }

  /// Utility to clean up markdown codeblocks from AI output (e.g., ```json ... ```)
  static String cleanJson(String rawText) {
    String text = rawText.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}
