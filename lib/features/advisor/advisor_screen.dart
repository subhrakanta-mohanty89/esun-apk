/// ESUN AI Advisor Screen - KANTA
/// 
/// AI-powered financial advisor with chat interface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../theme/theme.dart';
import '../../state/transaction_state.dart';

/// Chat messages provider
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([
    ChatMessage(
      content: "Namaste! I'm KANTA, your personal finance advisor.\n\n"
          "I can help you in:\n"
          "English, Hindi, Telugu, Tamil, Malayalam, Kannada\n\n"
          "Budget & spending analysis\n"
          "Check all bank balances\n"
          "Track your transactions\n"
          "Investment guidance\n\n"
          "Just ask me anything in your language!\n\n"
          "⚠️ Disclaimer: Kantha provides AI-generated insights based on your financial data for informational and educational purposes only. These insights are not financial advice. Always conduct your own research or consult a qualified professional from our expert marketplace before making any financial decisions.",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ]);
  
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }
  
  void addAIResponse(String content) {
    state = [...state, ChatMessage(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    )];
  }

  void reset(List<ChatMessage> messages) {
    state = [...messages];
  }

  void clear() {
    state = [];
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestions;
  
  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
  });
}

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});
  
  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _partialTranscript = '';
  String _selectedLanguage = 'English';
  
  // Multilingual quick suggestions
  final Map<String, List<String>> _multilingualSuggestions = {
    'English': [
      'What is my total bank balance?',
      'Show my recent transactions',
      'How can I save more?',
      'Investment advice',
    ],
    'Hindi': [
      'मेरा कुल बैंक बैलेंस क्या है?',
      'मेरे हाल के transactions दिखाओ',
      'मैं ज्यादा पैसे कैसे बचा सकता हूं?',
      'निवेश की सलाह दो',
    ],
    'Telugu': [
      'నా మొత్తం బ్యాంక్ బ్యాలెన్స్ ఎంత?',
      'నా ఇటీవలి లావాదేవీలు చూపించు',
      'నేను ఎక్కువ డబ్బు ఎలా ఆదా చేయగలను?',
      'పెట్టుబడి సలహా ఇవ్వండి',
    ],
    'Tamil': [
      'என் மொத்த வங்கி இருப்பு என்ன?',
      'என் சமீபத்திய பரிவர்த்தனைகள்',
      'நான் எப்படி அதிகம் சேமிக்க முடியும்?',
      'முதலீட்டு ஆலோசனை',
    ],
    'Malayalam': [
      'എന്റെ മൊത്തം ബാങ്ക് ബാലൻസ് എത്ര?',
      'എന്റെ സമീപകാല ഇടപാടുകൾ',
      'കൂടുതൽ പണം എങ്ങനെ ലാഭിക്കാം?',
      'നിക്ഷേപ ഉപദേശം',
    ],
    'Kannada': [
      'ನನ್ನ ಒಟ್ಟು ಬ್ಯಾಂಕ್ ಬ್ಯಾಲೆನ್ಸ್ ಎಷ್ಟು?',
      'ನನ್ನ ಇತ್ತೀಚಿನ ವಹಿವಾಟುಗಳು',
      'ನಾನು ಹೆಚ್ಚು ಹಣವನ್ನು ಹೇಗೆ ಉಳಿಸಬಹುದು?',
      'ಹೂಡಿಕೆ ಸಲಹೆ',
    ],
  };
  
  List<String> get _quickSuggestions => _multilingualSuggestions[_selectedLanguage] ?? _multilingualSuggestions['English']!;
  
  // Sample chat history sessions
  final List<Map<String, dynamic>> _chatHistory = [
    {'title': 'Investment advice', 'date': 'Today, 10:30 AM', 'preview': 'How should I invest my savings?'},
    {'title': 'Budget planning', 'date': 'Yesterday, 3:45 PM', 'preview': 'Help me create a monthly budget'},
    {'title': 'Loan query', 'date': 'Dec 15, 2024', 'preview': 'What are the best home loan options?'},
    {'title': 'Tax savings tips', 'date': 'Dec 10, 2024', 'preview': 'How can I save on income tax?'},
    {'title': 'SIP recommendations', 'date': 'Dec 5, 2024', 'preview': 'Suggest good SIP mutual funds'},
  ];

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (error) {
        setState(() {
          _isListening = false;
          _speechAvailable = false;
        });
        _showToast('Voice not available: ${error.errorMsg}');
      },
    );
    setState(() => _speechAvailable = available);
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _toggleVoiceInput() async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _partialTranscript = '';
    });

    await _speechToText.listen(onResult: (result) {
      setState(() {
        _partialTranscript = result.recognizedWords;
        if (result.finalResult) {
          _messageController.text = result.recognizedWords;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
          _isListening = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.history, color: ESUNColors.primary),
                  const SizedBox(width: ESUNSpacing.sm),
                  Text(
                    'Chat History',
                    style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ESUNColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: ESUNColors.primary, size: 20),
                    ),
                    title: Text(chat['title'], style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat['preview'], style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(chat['date'], style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: ESUNColors.textTertiary,
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat deleted'), duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Loading: ${chat['title']}'), duration: const Duration(seconds: 2)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: ESUNColors.primary),
              title: const Text('New Chat'),
              subtitle: const Text('Start a fresh conversation'),
              onTap: () {
                Navigator.pop(context);
                // Clear messages and add welcome message
                ref.read(chatMessagesProvider.notifier).reset([
                  ChatMessage(
                    content: "Namaste! I'm KANTA, your personal finance advisor.\n\n"
                        "I can help you in:\n"
                        "English, Hindi, Telugu, Tamil, Malayalam, Kannada\n\n"
                        "Budget & spending analysis\n"
                        "Check all bank balances\n"
                        "Track your transactions\n"
                        "Investment guidance\n\n"
                        "Just ask me anything in your language!\n\n"
                        "⚠️ Disclaimer: Kantha provides AI-generated insights based on your financial data for informational and educational purposes only. These insights are not financial advice. Always conduct your own research or consult a qualified professional from our expert marketplace before making any financial decisions.",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                ]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New chat started'), duration: Duration(seconds: 2)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.orange),
              title: const Text('Clear Chat'),
              subtitle: const Text('Remove all messages'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Chat?'),
                    content: const Text('This will remove all messages from the current conversation.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(chatMessagesProvider.notifier).clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat cleared'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.blue),
              title: const Text('Export Chat'),
              subtitle: const Text('Save conversation as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting chat...'), duration: Duration(seconds: 2)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: Colors.purple),
              title: const Text('KANTA Settings'),
              subtitle: const Text('Customize AI behavior'),
              onTap: () {
                Navigator.pop(context);
                _showKantaSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('About KANTA'),
              subtitle: const Text('Version 2.1.0'),
              onTap: () {
                Navigator.pop(context);
                _showAboutKanta();
              },
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  void _showKantaSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Text('KANTA Settings', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: ESUNSpacing.lg),
            SwitchListTile(
              title: const Text('Proactive Suggestions'),
              subtitle: const Text('Get personalized financial tips'),
              value: true,
              onChanged: (val) {},
              activeColor: ESUNColors.primary,
            ),
            SwitchListTile(
              title: const Text('Spending Alerts'),
              subtitle: const Text('Notify on unusual spending'),
              value: true,
              onChanged: (val) {},
              activeColor: ESUNColors.primary,
            ),
            SwitchListTile(
              title: const Text('Voice Input'),
              subtitle: const Text('Use voice to ask questions'),
              value: false,
              onChanged: (val) {},
              activeColor: ESUNColors.primary,
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  void _showAboutKanta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            const Text('KANTA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your AI Financial Advisor'),
            const SizedBox(height: ESUNSpacing.md),
            Text('Version: 2.1.0', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
            const SizedBox(height: ESUNSpacing.sm),
            const Text('KANTA uses advanced AI to provide personalized financial guidance based on your spending habits, goals, and preferences.'),
            const SizedBox(height: ESUNSpacing.md),
            Text('Powered by ESUN AI', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: ESUNAnimations.fast,
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    ref.read(chatMessagesProvider.notifier).addMessage(
      ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    
    _messageController.clear();
    _scrollToBottom();
    
    // Show typing indicator
    setState(() => _isTyping = true);
    
    // Simulate AI response
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() => _isTyping = false);
    
    // Generate response based on query
    String response = _generateResponse(message);
    
    ref.read(chatMessagesProvider.notifier).addAIResponse(response);
    _scrollToBottom();
  }
  
  String _generateResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('save') || lowerQuery.contains('saving')) {
      return "Based on your spending patterns, here are some savings tips:\n\n"
          "1️⃣ **Reduce dining out** - You spent ₹8,500 last month. Consider meal prepping to save ₹5,000/month.\n\n"
          "2️⃣ **Subscription audit** - You have 6 active subscriptions (₹2,340/month). Consider canceling unused ones.\n\n"
          "3️⃣ **Automate savings** - Set up a ₹10,000 auto-transfer on salary day.\n\n"
          "Would you like me to set up an automated savings plan for you?";
    } else if (lowerQuery.contains('spend') || lowerQuery.contains('expense')) {
      return "📊 **Your Spending Analysis (Last 30 days)**\n\n"
          "• Food & Dining: ₹12,500 (25%)\n"
          "• Shopping: ₹8,400 (17%)\n"
          "• Transport: ₹6,200 (12%)\n"
          "• Bills & Utilities: ₹5,800 (12%)\n"
          "• Entertainment: ₹4,500 (9%)\n"
          "• Others: ₹12,600 (25%)\n\n"
          "⚠️ **Alert:** Food spending is 30% higher than last month.\n\n"
          "Would you like tips to reduce your food expenses?";
    } else if (lowerQuery.contains('invest') || lowerQuery.contains('investment')) {
      return "Based on your risk profile and goals, here are my recommendations:\n\n"
          "**For Emergency Fund (Low Risk)**\n"
          "• Liquid Funds - ₹3L (6-7% returns)\n\n"
          "**For Wealth Building (Moderate Risk)**\n"
          "• Large Cap Funds - ₹15K/month SIP\n"
          "• Index Funds - ₹10K/month SIP\n\n"
          "**For High Growth (Higher Risk)**\n"
          "• Mid & Small Cap - ₹5K/month SIP\n\n"
          "📈 Projected growth: ₹45L in 10 years\n\n"
          "Want me to help you start a SIP?";
    } else if (lowerQuery.contains('transaction') || lowerQuery.contains('last payment') || lowerQuery.contains('recent') || lowerQuery.contains('history')) {
      final txns = ref.read(transactionStateProvider).transactions;
      if (txns.isEmpty) {
        return "You don't have any transactions yet. Make a payment and I'll track it for you!";
      }
      final last = txns.first;
      final bankName = (last.sourceAccount != null && last.sourceAccount!.isNotEmpty)
          ? last.sourceAccount!
          : 'HDFC Bank •• 1234';
      final typeLabel = last.isDebit ? 'Paid' : 'Received';
      final timeAgo = DateTime.now().difference(last.timestamp);
      String timeStr;
      if (timeAgo.inMinutes < 60) {
        timeStr = '${timeAgo.inMinutes} minutes ago';
      } else if (timeAgo.inHours < 24) {
        timeStr = '${timeAgo.inHours} hours ago';
      } else {
        timeStr = '${timeAgo.inDays} days ago';
      }
      
      // Build last 5 transactions list
      final recentList = txns.take(5).map((t) {
        final src = (t.sourceAccount != null && t.sourceAccount!.isNotEmpty) ? t.sourceAccount! : 'HDFC Bank';
        final sign = t.isDebit ? '-' : '+';
        return '• ${t.title} — $sign₹${t.amount.toStringAsFixed(0)} from $src';
      }).join('\n');
      
      return "📝 **Your Last Transaction**\n\n"
          "**$typeLabel:** ₹${last.amount.toStringAsFixed(0)}\n"
          "**To:** ${last.recipientName ?? last.title}\n"
          "**From:** $bankName\n"
          "**Category:** ${last.category ?? 'Transfer'}\n"
          "**When:** $timeStr\n"
          "**Status:** ${last.status.name.toUpperCase()}\n\n"
          "📋 **Recent Transactions:**\n$recentList\n\n"
          "Would you like more details about any of these?";
    } else if (lowerQuery.contains('budget')) {
      return "📋 **Suggested Budget for Your Income (₹1.2L/month)**\n\n"
          "Essential Expenses (50%): ₹60,000\n"
          "• Rent/EMI: ₹25,000\n"
          "• Groceries: ₹8,000\n"
          "• Bills & Utilities: ₹7,000\n"
          "• Transport: ₹5,000\n"
          "• Insurance: ₹5,000\n"
          "• Others: ₹10,000\n\n"
          "Investments (30%): ₹36,000\n"
          "• SIPs: ₹25,000\n"
          "• FD/RD: ₹11,000\n\n"
          "Lifestyle (20%): ₹24,000\n"
          "• Dining/Entertainment\n"
          "• Shopping\n"
          "• Travel\n\n"
          "Should I set up this budget for you?";
    } else {
      return "I can help you with that! Here are some things I can assist you with:\n\n"
          "💡 **Financial Analysis**\n"
          "• Spending patterns & insights\n"
          "• Income vs expense tracking\n\n"
          "📈 **Investment Guidance**\n"
          "• Personalized recommendations\n"
          "• Risk assessment\n\n"
          "🎯 **Goal Planning**\n"
          "• Create & track financial goals\n"
          "• Savings strategies\n\n"
          "What would you like to explore?";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? ESUNColors.darkBackground : ESUNColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KANTA'),
                Text(
                  'AI Financial Advisor',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate),
            tooltip: 'Select Language',
            onSelected: (lang) {
              setState(() => _selectedLanguage = lang);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language: $lang'), duration: const Duration(seconds: 1)),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'English', child: Text('🇬🇧 English')),
              const PopupMenuItem(value: 'Hindi', child: Text('🇮🇳 हिंदी (Hindi)')),
              const PopupMenuItem(value: 'Telugu', child: Text('🇮🇳 తెలుగు (Telugu)')),
              const PopupMenuItem(value: 'Tamil', child: Text('🇮🇳 தமிழ் (Tamil)')),
              const PopupMenuItem(value: 'Malayalam', child: Text('🇮🇳 മലയാളം (Malayalam)')),
              const PopupMenuItem(value: 'Kannada', child: Text('🇮🇳 ಕನ್ನಡ (Kannada)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistorySheet,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          
          // Quick suggestions
          if (messages.length <= 2)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                itemCount: _quickSuggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: ESUNSpacing.sm),
                    child: ActionChip(
                      label: Text(_quickSuggestions[index]),
                      onPressed: () => _sendMessage(_quickSuggestions[index]),
                      backgroundColor: ESUNColors.surfaceVariant,
                    ),
                  );
                },
              ),
            ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: ESUNSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: isUser 
                    ? ESUNColors.primary 
                    : ESUNColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: ESUNTypography.bodyMedium.copyWith(
                  color: isUser ? Colors.white : ESUNColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: ESUNSpacing.xl),
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
              ),
              shape: BoxShape.circle,
            ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: ESUNSpacing.sm),
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: const BoxDecoration(
              color: ESUNColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ESUNColors.textTertiary.withOpacity(0.5 + (0.5 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isListening ? Icons.stop_circle : Icons.mic_outlined,
                  color: _isListening ? ESUNColors.primary : null),
              tooltip: _isListening ? 'Stop listening' : 'Voice input',
              onPressed: _toggleVoiceInput,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _isListening && _partialTranscript.isNotEmpty
                      ? _partialTranscript
                      : 'Ask KANTA anything...',
                  filled: true,
                  fillColor: ESUNColors.surfaceVariant,
                  border: const OutlineInputBorder(
                    borderRadius: ESUNRadius.fullRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ESUNSpacing.lg,
                    vertical: ESUNSpacing.md,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



