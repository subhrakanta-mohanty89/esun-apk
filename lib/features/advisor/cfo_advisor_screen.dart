/// CFO AI Advisor Screen
/// 
/// AI-powered financial advisor that analyzes your bank statement
/// and provides data-driven advice based on 12 financial rules.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../theme/theme.dart';
import 'cfo_service.dart';

class CFOAdvisorScreen extends ConsumerStatefulWidget {
  const CFOAdvisorScreen({super.key});

  @override
  ConsumerState<CFOAdvisorScreen> createState() => _CFOAdvisorScreenState();
}

class _CFOAdvisorScreenState extends ConsumerState<CFOAdvisorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Speech-to-text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // Text-to-speech
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String? _speakingMessageId;
  
  // Language selection
  String _selectedLanguage = 'English';
  
  final Map<String, String> _languageLocales = {
    'English': 'en_IN',
    'Hindi': 'hi_IN',
    'Telugu': 'te_IN',
    'Tamil': 'ta_IN',
    'Malayalam': 'ml_IN',
    'Kannada': 'kn_IN',
  };
  
  final Map<String, List<String>> _multilingualSuggestions = {
    'English': [
      'What is my total bank balance?',
      'Show my recent transactions',
      'Which financial rule suits me?',
      'How can I save more?',
      'Show my expense breakdown',
      'Analyze my spending',
    ],
    'Hindi': [
      'मेरा कुल बैंक बैलेंस क्या है?',
      'मेरे हाल के transactions दिखाओ',
      'मुझे कौन सा financial rule अपनाना चाहिए?',
      'मैं ज्यादा पैसे कैसे बचा सकता हूं?',
      'मेरा खर्चा breakdown दिखाओ',
      'मेरे खर्चों का analysis करो',
    ],
    'Telugu': [
      'నా మొత్తం బ్యాంక్ బ్యాలెన్స్ ఎంత?',
      'నా ఇటీవలి లావాదేవీలు చూపించు',
      'నాకు ఏ సూత్రం సరిపోతుంది?',
      'నేను ఎక్కువ ఆదా చేయడం ఎలా?',
      'నా ఖర్చుల వివరాలు చూపించు',
      'నా ఖర్చుల విశ్లేషణ చేయి',
    ],
    'Tamil': [
      'என் மொத்த வங்கி இருப்பு என்ன?',
      'என் சமீபத்திய பரிவர்த்தனைகள்',
      'எந்த விதி எனக்கு சரியானது?',
      'நான் எப்படி அதிகம் சேமிக்க முடியும்?',
      'என் செலவு விவரங்கள்',
      'என் செலவுகளை பகுப்பாய்வு செய்',
    ],
    'Malayalam': [
      'എന്റെ മൊത്തം ബാങ്ക് ബാലൻസ് എത്ര?',
      'എന്റെ സമീപകാല ഇടപാടുകൾ',
      'ഏത് നിയമം എനിക്ക് അനുയോജ്യം?',
      'കൂടുതൽ പണം എങ്ങനെ ലാഭിക്കാം?',
      'എന്റെ ചെലവ് വിശദാംശങ്ങൾ',
      'എന്റെ ചെലവുകൾ വിശകലനം ചെയ്യുക',
    ],
    'Kannada': [
      'ನನ್ನ ಒಟ್ಟು ಬ್ಯಾಂಕ್ ಬ್ಯಾಲೆನ್ಸ್ ಎಷ್ಟು?',
      'ನನ್ನ ಇತ್ತೀಚಿನ ವಹಿವಾಟುಗಳು',
      'ನನಗೆ ಯಾವ ನಿಯಮ ಸರಿಹೊಂದುತ್ತದೆ?',
      'ನಾನು ಹೆಚ್ಚು ಉಳಿಸುವುದು ಹೇಗೆ?',
      'ನನ್ನ ಖರ್ಚಿನ ವಿವರಗಳು',
      'ನನ್ನ ಖರ್ಚುಗಳ ವಿಶ್ಲೇಷಣೆ',
    ],
  };
  
  List<String> get _quickSuggestions => _multilingualSuggestions[_selectedLanguage] ?? _multilingualSuggestions['English']!;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (errorNotification) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(_languageLocales[_selectedLanguage] ?? 'en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() {
        _isSpeaking = false;
        _speakingMessageId = null;
      });
    });
  }
  
  Future<void> _updateTtsLanguage(String language) async {
    final locale = _languageLocales[language] ?? 'en-IN';
    await _tts.setLanguage(locale.replaceAll('_', '-'));
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _messageController.text = result.recognizedWords;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _sendMessage(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: _languageLocales[_selectedLanguage] ?? 'en_IN',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speakMessage(CFOMessage message) async {
    if (_isSpeaking && _speakingMessageId == message.content) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _speakingMessageId = null;
      });
      return;
    }
    setState(() {
      _isSpeaking = true;
      _speakingMessageId = message.content;
    });
    await _tts.speak(message.content);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
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

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _messageController.clear();
    await ref.read(cfoChatProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  void _showSummarySheet() {
    final summary = ref.read(cfoChatProvider).summary;
    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading financial summary...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(ESUNSpacing.lg),
          child: ListView(
            controller: scrollController,
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
              Row(
                children: [
                  const Icon(Icons.analytics, color: ESUNColors.primary),
                  const SizedBox(width: ESUNSpacing.sm),
                  Text(
                    'Financial Summary',
                    style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: ESUNSpacing.lg),
              
              // Income & Expenses
              _buildSummaryCard(
                'Income vs Expenses',
                [
                  _buildMetricRow('Total Income', '₹${_formatNumber(summary.totalIncome)}', Colors.green),
                  _buildMetricRow('Total Expenses', '₹${_formatNumber(summary.totalExpenses)}', Colors.red),
                  _buildMetricRow('Net Savings', '₹${_formatNumber(summary.netSavings)}', 
                    summary.netSavings >= 0 ? Colors.green : Colors.red),
                ],
              ),
              
              const SizedBox(height: ESUNSpacing.md),
              
              // Key Metrics
              _buildSummaryCard(
                'Key Metrics',
                [
                  _buildMetricRow('Savings Rate', '${summary.savingsRate.toStringAsFixed(1)}%', 
                    summary.savingsRate >= 20 ? Colors.green : Colors.orange),
                  _buildMetricRow('Needs', '${summary.needsPercentage.toStringAsFixed(1)}%', Colors.blue),
                  _buildMetricRow('Wants', '${summary.wantsPercentage.toStringAsFixed(1)}%', Colors.purple),
                  _buildMetricRow('Daily Average Expense', '₹${_formatNumber(summary.dailyAverageExpense)}', Colors.grey),
                ],
              ),
              
              const SizedBox(height: ESUNSpacing.md),
              
              // Recommended Rules
              if (summary.recommendedRules.isNotEmpty) ...[
                _buildSummaryCard(
                  'Recommended Financial Rules',
                  summary.recommendedRules.map((rule) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: ESUNColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule, style: ESUNTypography.bodyMedium)),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ],
              
              const SizedBox(height: ESUNSpacing.md),
              
              // Categories
              if (summary.categories.isNotEmpty)
                _buildSummaryCard(
                  'Expense Categories',
                  summary.categories.entries.map((e) => 
                    _buildMetricRow(e.key, '₹${_formatNumber(e.value)}', _getCategoryColor(e.key)),
                  ).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ESUNTypography.bodyMedium),
          Text(value, style: ESUNTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          )),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'shopping': return Colors.purple;
      case 'travel': return Colors.blue;
      case 'utilities': return Colors.teal;
      case 'health': return Colors.red;
      case 'entertainment': return Colors.pink;
      case 'groceries': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatNumber(double number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(cfoChatProvider);

    // Auto-scroll when new messages arrive
    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KANTHA'),
                Text(
                  'Your Financial Coach',
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
            onSelected: (lang) async {
              setState(() => _selectedLanguage = lang);
              await _updateTtsLanguage(lang);
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
            icon: const Icon(Icons.analytics),
            tooltip: 'Financial Summary',
            onPressed: _showSummarySheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'reset':
                  await ref.read(cfoChatProvider.notifier).resetConversation();
                  break;
                case 'refresh':
                  await ref.read(cfoServiceProvider).refreshData();
                  await ref.read(cfoChatProvider.notifier).loadSummary();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data refreshed')),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('New Conversation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
            ],
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
              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(chatState.messages[index]);
              },
            ),
          ),

          // Quick suggestions
          if (chatState.messages.length <= 2)
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickSuggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_quickSuggestions[index]),
                      backgroundColor: ESUNColors.primary.withOpacity(0.1),
                      labelStyle: ESUNTypography.labelMedium.copyWith(
                        color: ESUNColors.primary,
                      ),
                      onPressed: () => _sendMessage(_quickSuggestions[index]),
                    ),
                  );
                },
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: ESUNSpacing.lg,
              right: ESUNSpacing.lg,
              top: ESUNSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + ESUNSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your finances...',
                      filled: true,
                      fillColor: ESUNColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ESUNSpacing.lg,
                        vertical: ESUNSpacing.md,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    enabled: !chatState.isLoading,
                  ),
                ),
                const SizedBox(width: ESUNSpacing.sm),
                // Mic button for speech-to-text
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : ESUNColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: chatState.isLoading
                        ? null
                        : (_isListening ? _stopListening : _startListening),
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.white : ESUNColors.primary,
                    ),
                    tooltip: _isListening ? 'Stop listening' : 'Speak',
                  ),
                ),
                const SizedBox(width: ESUNSpacing.xs),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: chatState.isLoading 
                        ? null 
                        : () => _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CFOMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? ESUNColors.primary
                        : ESUNColors.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                  ),
                  child: message.isUser
                      ? Text(
                          message.content,
                          style: ESUNTypography.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.textPrimary,
                            ),
                            strong: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.textPrimary,
                            ),
                            h1: ESUNTypography.titleLarge.copyWith(
                              color: ESUNColors.textPrimary,
                            ),
                            h2: ESUNTypography.titleMedium.copyWith(
                              color: ESUNColors.textPrimary,
                            ),
                            h3: ESUNTypography.titleSmall.copyWith(
                              color: ESUNColors.textPrimary,
                            ),
                            code: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.primary,
                              backgroundColor: ESUNColors.primary.withOpacity(0.1),
                            ),
                            tableHead: ESUNTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            tableBody: ESUNTypography.bodyMedium,
                          ),
                          selectable: true,
                        ),
                ),
                // TTS button for AI messages
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                      onTap: () => _speakMessage(message),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSpeaking && _speakingMessageId == message.content
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_outlined,
                              size: 16,
                              color: ESUNColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isSpeaking && _speakingMessageId == message.content
                                  ? 'Stop'
                                  : 'Listen',
                              style: ESUNTypography.labelSmall.copyWith(
                                color: ESUNColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: ESUNColors.primary, size: 16),
            ),
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
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: ESUNColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
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
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 200),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (value < 0.5 ? value : 1 - value)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}



