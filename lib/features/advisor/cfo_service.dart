/// CFO Advisor Service
/// 
/// Service for calling the CFO AI chatbot API endpoints.

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

  CFOChatNotifier(this._service) : super(const CFOChatState()) {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Add static welcome message with multilingual support
    final welcomeMessage = CFOMessage(
      content: "Namaste! I'm KANTA, your AI financial advisor.\n\n"
          "I can help you in:\n"
          "English, Hindi, Telugu, Tamil, Malayalam, Kannada\n\n"
          "Check all your bank balances\n"
          "Track your transactions\n"
          "Get personalized financial advice\n"
          "Plan your savings & investments\n\n"
          "Just ask in your preferred language!\n\n"
          "⚠️ Disclaimer: Kantha provides AI-generated insights based on your financial data for informational and educational purposes only. These insights are not financial advice. Always conduct your own research or consult a qualified professional from our expert marketplace before making any financial decisions.",
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
      final response = await _service.chat(message, sessionId: _sessionId);
      
      if (response != null) {
        _sessionId = response['session_id'];
        final aiMessage = CFOMessage(
          content: response['message'] ?? 'Unable to generate response',
          isUser: false,
        );
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          messages: [
            ...state.messages,
            CFOMessage(
              content: "Sorry, I couldn't process your request. Please try again.",
              isUser: false,
            ),
          ],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          CFOMessage(
            content: "Error: ${e.toString()}",
            isUser: false,
          ),
        ],
        isLoading: false,
        error: e.toString(),
      );
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
  Future<Map<String, dynamic>?> chat(String message, {String? sessionId}) async {
    try {
      final response = await _dio.post(
        '/api/v1/cfo/chat',
        data: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
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
}



