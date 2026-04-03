/// CFO Advisor Service
/// 
/// Service for calling the CFO AI chatbot API endpoints.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_service.dart';

/// CFO Service Provider
final cfoServiceProvider = Provider<CFOService>((ref) {
  return CFOService(ref.watch(dioProvider));
});

/// CFO Chat State
class CFOChatState {
  final List<CFOMessage> messages;
  final bool isLoading;
  final String? error;
  final FinancialSummary? summary;

  const CFOChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.summary,
  });

  CFOChatState copyWith({
    List<CFOMessage>? messages,
    bool? isLoading,
    String? error,
    FinancialSummary? summary,
  }) {
    return CFOChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
    );
  }
}

/// Single CFO Chat Message
class CFOMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  CFOMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Financial Summary Model
class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;
  final Map<String, double> categories;
  final double needs;
  final double wants;
  final double needsPercentage;
  final double wantsPercentage;
  final double dailyAverageExpense;
  final List<String> recommendedRules;
  final int transactionsCount;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
    required this.categories,
    required this.needs,
    required this.wants,
    required this.needsPercentage,
    required this.wantsPercentage,
    required this.dailyAverageExpense,
    required this.recommendedRules,
    required this.transactionsCount,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalIncome: (json['total_income'] ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      netSavings: (json['net_savings'] ?? 0).toDouble(),
      savingsRate: (json['savings_rate'] ?? 0).toDouble(),
      categories: Map<String, double>.from(
        (json['categories'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0).toDouble()),
        ),
      ),
      needs: (json['needs'] ?? 0).toDouble(),
      wants: (json['wants'] ?? 0).toDouble(),
      needsPercentage: (json['needs_percentage'] ?? 0).toDouble(),
      wantsPercentage: (json['wants_percentage'] ?? 0).toDouble(),
      dailyAverageExpense: (json['daily_average_expense'] ?? 0).toDouble(),
      recommendedRules: List<String>.from(json['recommended_rules'] ?? []),
      transactionsCount: json['transactions_count'] ?? 0,
    );
  }
}

/// CFO Chat State Notifier
class CFOChatNotifier extends StateNotifier<CFOChatState> {
  final CFOService _service;
  String? _sessionId;
  int _healthScore = 0;
  String _healthLabel = 'Fair';

  CFOChatNotifier(this._service) : super(const CFOChatState()) {
    _initializeChat();
  }

  /// Update health data from AA state for personalized responses
  void updateHealthData(int score, String label) {
    _healthScore = score;
    _healthLabel = label;
  }

  /// Whether the user has a strong financial profile (score >= 65)
  bool get isStrongProfile => _healthScore >= 65;

  Future<void> _initializeChat() async {
    // Personalized welcome based on health profile
    final String profileHint;
    final String capabilities;
    if (_healthScore >= 80) {
      profileHint = "Your finances look excellent! Let's explore wealth-building and advanced strategies together.";
      capabilities = "**What I can do for you:**\n"
          "- Optimize your investment portfolio & suggest rebalancing\n"
          "- Plan long-term goals (retirement, FIRE, child education)\n"
          "- Recommend SIP step-ups & tax-saving strategies\n"
          "- Evaluate surplus utilization (liquid funds, sweep-in FD)\n"
          "- Assess insurance adequacy & advanced planning\n"
          "- Give pros & cons for every recommendation";
    } else if (_healthScore >= 65) {
      profileHint = "You're doing well financially! I can help you grow your wealth and plan for bigger goals.";
      capabilities = "**What I can do for you:**\n"
          "- Grow your investments with smart SIP recommendations\n"
          "- Review portfolio allocation & suggest optimization\n"
          "- Plan long-term financial milestones\n"
          "- Find better use for idle bank surplus\n"
          "- Evaluate insurance & loan prepayment options\n"
          "- Give pros & cons for every recommendation";
    } else if (_healthScore >= 50) {
      profileHint = "Your finances need some attention. Let's work together on building better habits.";
      capabilities = "**What I can do for you:**\n"
          "- Create a budget plan that works for you\n"
          "- Identify spending leaks & reduce unnecessary expenses\n"
          "- Help build an emergency fund step by step\n"
          "- Recommend safe investment options (RDs, liquid funds)\n"
          "- Prioritize which debts to pay off first\n"
          "- Give small, achievable weekly action items";
    } else {
      profileHint = "I'm here to help you improve your finances step by step. Let's start with quick wins today.";
      capabilities = "**What I can do for you:**\n"
          "- Stop the cash-flow drain — cut expenses safely\n"
          "- Create a zero-based budget for next month\n"
          "- Build your first emergency fund (even ₹500/week)\n"
          "- Tackle high-interest debt with Avalanche method\n"
          "- Improve financial discipline with daily habits\n"
          "- Give one clear action to focus on each week";
    }
    
    final welcomeMessage = CFOMessage(
      content: "Namaste! I'm **KANTA**, your AI financial advisor.\n\n"
          "$profileHint\n\n"
          "I speak: English, Hindi, Telugu, Tamil, Malayalam, Kannada\n\n"
          "$capabilities\n\n"
          "Just ask me anything in your preferred language!\n\n"
          "_Disclaimer: Kanta provides AI-generated insights for informational purposes only — not financial advice. "
          "Consult a qualified professional before making financial decisions._",
      isUser: false,
    );
    state = state.copyWith(messages: [welcomeMessage]);
    
    // Load financial summary from API (no static defaults)
    await loadSummary();
  }

  Future<void> loadSummary() async {
    try {
      final summary = await _service.getSummary();
      if (summary != null) {
        state = state.copyWith(summary: summary);
      }
    } catch (e) {
      // Summary loading is optional, don't show error
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = CFOMessage(content: message, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final stopwatch = Stopwatch()..start();

      // Add a placeholder AI message that will be filled chunk-by-chunk
      final aiMessage = CFOMessage(content: '', isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
      );

      final buffer = StringBuffer();
      await for (final chunk in streamChatResponse(
        _service._dio,
        path: '/api/v1/cfo/chat/stream',
        data: {
          'message': message,
          if (_sessionId != null) 'session_id': _sessionId,
          if (_healthScore > 0) 'health_score': _healthScore,
          'health_label': _healthLabel,
        },
      )) {
        buffer.write(chunk);
        // Update the last message in place for progressive rendering
        final updated = List<CFOMessage>.from(state.messages);
        updated[updated.length - 1] = CFOMessage(
          content: buffer.toString(),
          isUser: false,
        );
        state = state.copyWith(messages: updated);
      }

      stopwatch.stop();
      debugPrint('⏱️ CFO stream completed in ${stopwatch.elapsedMilliseconds}ms');

      // Final state — mark loading done
      final finalContent = buffer.toString();
      if (finalContent.isEmpty) {
        final updated = List<CFOMessage>.from(state.messages);
        updated[updated.length - 1] = CFOMessage(
          content: "Sorry, I couldn't process your request. Please try again.",
          isUser: false,
        );
        state = state.copyWith(messages: updated, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      // Fallback: if streaming fails, try the blocking endpoint
      try {
        final response = await _service.chat(
          message,
          sessionId: _sessionId,
          healthScore: _healthScore,
          healthLabel: _healthLabel,
        );
        if (response != null) {
          _sessionId = response['session_id'];
          final updated = List<CFOMessage>.from(state.messages);
          updated[updated.length - 1] = CFOMessage(
            content: response['message'] ?? 'Unable to generate response',
            isUser: false,
          );
          state = state.copyWith(messages: updated, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false, error: e.toString());
        }
      } catch (fallbackError) {
        final updated = List<CFOMessage>.from(state.messages);
        updated[updated.length - 1] = CFOMessage(
          content: "Error: ${fallbackError.toString()}",
          isUser: false,
        );
        state = state.copyWith(
          messages: updated,
          isLoading: false,
          error: fallbackError.toString(),
        );
      }
    }
  }

  Future<void> resetConversation() async {
    await _service.resetConversation(sessionId: _sessionId);
    _sessionId = null;
    _initializeChat();
  }
}

/// CFO Chat Provider
final cfoChatProvider = StateNotifierProvider<CFOChatNotifier, CFOChatState>((ref) {
  return CFOChatNotifier(ref.watch(cfoServiceProvider));
});

/// CFO Service - API calls
class CFOService {
  final Dio _dio;

  CFOService(this._dio);

  /// Send a chat message to CFO AI
  Future<Map<String, dynamic>?> chat(String message, {String? sessionId, int? healthScore, String? healthLabel}) async {
    try {
      final response = await _dio.post(
        '/api/v1/cfo/chat',
        data: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          if (healthScore != null) 'health_score': healthScore,
          if (healthLabel != null) 'health_label': healthLabel,
        },
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Chat failed');
    }
  }

  /// Get financial summary
  Future<FinancialSummary?> getSummary() async {
    try {
      final response = await _dio.get(
        '/api/v1/cfo/summary',
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return FinancialSummary.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to get summary');
    }
  }

  /// Get all transactions
  Future<List<Map<String, dynamic>>?> getTransactions() async {
    try {
      final response = await _dio.get(
        '/api/v1/cfo/transactions',
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          response.data['data']['transactions'] ?? [],
        );
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to get transactions');
    }
  }

  /// Get financial rules recommendations
  Future<Map<String, dynamic>?> getRules() async {
    try {
      final response = await _dio.get(
        '/api/v1/cfo/rules',
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to get rules');
    }
  }

  /// Reset conversation
  Future<void> resetConversation({String? sessionId}) async {
    try {
      await _dio.post(
        '/api/v1/cfo/reset',
        data: {
          if (sessionId != null) 'session_id': sessionId,
        },
        options: Options(extra: {'skipAuth': true}),
      );
    } catch (e) {
      // Silent fail for reset
    }
  }

  /// Refresh CFO data
  Future<void> refreshData() async {
    try {
      await _dio.post(
        '/api/v1/cfo/refresh',
        options: Options(extra: {'skipAuth': true}),
      );
    } catch (e) {
      // Silent fail for refresh
    }
  }

  /// Convert text to speech via Sarvam AI (Indian male voice)
  /// Returns base64-encoded WAV audio, or null on failure.
  Future<String?> textToSpeech(String text, {String language = 'english'}) async {
    try {
      final response = await _dio.post(
        '/api/v1/cfo/tts',
        data: {
          'text': text,
          'language': language,
        },
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['audio_base64'] as String?;
      }
      return null;
    } catch (e) {
      return null;  // Fallback to device TTS silently
    }
  }
}



