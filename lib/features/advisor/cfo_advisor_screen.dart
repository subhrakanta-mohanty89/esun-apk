/// CFO AI Advisor Screen
/// 
/// AI-powered financial advisor that analyzes your bank statement
/// and provides data-driven advice based on 12 financial rules.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../theme/theme.dart';
import '../../state/aa_data_state.dart';
import '../../core/network/api_service.dart';
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

  // Suggestion chips toggle
  bool _suggestionsExpanded = false;

  // Text-to-speech (device fallback)
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String? _speakingMessageId;
  
  // Sarvam AI TTS (Indian male voice — primary)
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _useSarvam = true; // Try Sarvam first, fall back to device TTS
  
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
  
  // Health-profile-aware English suggestions
  final List<String> _strongProfileSuggestions = [
    'How can I optimize my investments?',
    'Suggest tax-saving strategies',
    'Should I increase my SIP amount?',
    'Is my insurance cover sufficient?',
    'What mutual funds should I consider?',
    'Analyze my spending behavior',
    'Should I prepay any loans?',
    'Where am I overspending?',
  ];
  
  final List<String> _weakProfileSuggestions = [
    'What is lowering my health score?',
    'Help me create a budget plan',
    'How do I build an emergency fund?',
    'Which debts should I pay off first?',
    'Where can I save money?',
    'Do I need life insurance?',
    'What are my next steps to improve?',
    'Is my spending under control?',
  ];
  
  List<String> get _quickSuggestions {
    if (_selectedLanguage != 'English') {
      return _multilingualSuggestions[_selectedLanguage] ?? _multilingualSuggestions['English']!;
    }
    final aaData = ref.read(aaDataProvider);
    if (aaData.healthScore >= 65) {
      return _strongProfileSuggestions;
    }
    return _weakProfileSuggestions;
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initAudioPlayer();
    // Sync financial health score to the chat notifier for personalized responses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncHealthData();
    });
  }
  
  void _syncHealthData() {
    final aaData = ref.read(aaDataProvider);
    ref.read(cfoChatProvider.notifier).updateHealthData(
      aaData.healthScore,
      aaData.healthLabel,
    );
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
    // Tuned for natural, pleasant, smooth conversational speech
    await _tts.setSpeechRate(0.45); // Smooth, easy-to-follow pace — not rushed
    await _tts.setVolume(0.9);      // Comfortable level — not harsh on ears
    await _tts.setPitch(1.0);       // Natural pitch — avoid deep/robotic tone

    // Try to select a high-quality voice for natural speech
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        final voiceList = List<Map<Object?, Object?>>.from(voices.cast<Map>());
        Map<Object?, Object?>? selectedVoice;
        
        // Priority: enhanced/premium voices > standard voices
        // Preference: Indian English > any English
        for (final v in voiceList) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          
          // Skip low-quality/compact voices
          if (name.contains('compact') || name.contains('legacy')) continue;
          
          // Prefer enhanced voices (iOS has "enhanced" and "premium" voices)
          final isEnhanced = name.contains('enhanced') || name.contains('premium') || name.contains('neural');
          
          if (locale.contains('en') && locale.contains('in')) {
            // Indian English voice — best match
            if (isEnhanced || selectedVoice == null) {
              selectedVoice = v;
              if (isEnhanced) break; // Premium Indian English — perfect
            }
          } else if (locale.contains('en') && selectedVoice == null) {
            selectedVoice = v;
          }
        }
        if (selectedVoice != null) {
          await _tts.setVoice({
            'name': selectedVoice['name'].toString(),
            'locale': selectedVoice['locale'].toString(),
          });
        }
      }
    } catch (_) {
      // Fallback to default voice with tuned pitch/rate
    }

    _tts.setCompletionHandler(() {
      if (mounted) setState(() {
        _isSpeaking = false;
        _speakingMessageId = null;
      });
    });
  }
  
  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageId = null;
        });
      }
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

  /// Preprocess text for natural, pleasant speech output
  String _prepareTextForSpeech(String text) {
    var cleaned = text;
    // Remove markdown formatting
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1'); // bold
    cleaned = cleaned.replaceAll(RegExp(r'\*(.+?)\*'), r'\1'); // italic
    cleaned = cleaned.replaceAll(RegExp(r'_(.+?)_'), r'\1'); // underscore italic
    cleaned = cleaned.replaceAll(RegExp(r'#{1,6}\s*'), ''); // headers
    cleaned = cleaned.replaceAll(RegExp(r'`(.+?)`'), r'\1'); // inline code
    cleaned = cleaned.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'\1'); // links
    // Clean bullet points
    cleaned = cleaned.replaceAll(RegExp(r'^[\-•]\s*', multiLine: true), '');
    // Strip emoji (surrogate pairs)
    cleaned = cleaned.replaceAll(RegExp(r'[\u{1F600}-\u{1F9FF}]', unicode: true), '');
    
    // Make symbols speakable
    cleaned = cleaned.replaceAll('₹', 'rupees ');
    cleaned = cleaned.replaceAll('%', ' percent');
    cleaned = cleaned.replaceAll('&', ' and ');
    
    // Expand common financial abbreviations for natural speech
    cleaned = cleaned.replaceAll(RegExp(r'\bSIP\b'), 'S.I.P.');
    cleaned = cleaned.replaceAll(RegExp(r'\bEMI\b'), 'E.M.I.');
    cleaned = cleaned.replaceAll(RegExp(r'\bFD\b'), 'F.D.');
    cleaned = cleaned.replaceAll(RegExp(r'\bRD\b'), 'R.D.');
    cleaned = cleaned.replaceAll(RegExp(r'\bNPS\b'), 'N.P.S.');
    cleaned = cleaned.replaceAll(RegExp(r'\bPPF\b'), 'P.P.F.');
    cleaned = cleaned.replaceAll(RegExp(r'\bELSS\b'), 'E.L.S.S.');
    
    // Insert natural pauses — paragraph breaks become sentence pauses
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r'\n{2}'), '. ');
    cleaned = cleaned.replaceAll('\n', ', ');
    // Collapse whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ');
    return cleaned.trim();
  }

  Future<void> _speakMessage(CFOMessage message) async {
    // Stop if currently speaking the same message
    if (_isSpeaking && _speakingMessageId == message.content) {
      await _audioPlayer.stop();
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
    
    // Try Sarvam AI TTS first (Indian male voice)
    if (_useSarvam) {
      try {
        final cfoService = ref.read(cfoServiceProvider);
        final audioBase64 = await cfoService.textToSpeech(
          _prepareTextForSpeech(message.content),
          language: _selectedLanguage.toLowerCase(),
        );
        
        if (audioBase64 != null && audioBase64.isNotEmpty) {
          final bytes = base64Decode(audioBase64);
          await _audioPlayer.play(
            BytesSource(Uint8List.fromList(bytes), mimeType: 'audio/wav'),
          );
          return; // Success — don't fall through
        }
      } catch (_) {
        // Fall through to device TTS
      }
    }
    
    // Fallback to device TTS
    await _tts.speak(_prepareTextForSpeech(message.content));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    _audioPlayer.dispose();
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
    // Use .select() to only rebuild when health data changes, not all AA data
    final healthScore = ref.watch(aaDataProvider.select((data) => data.healthScore));
    final healthLabel = ref.watch(aaDataProvider.select((data) => data.healthLabel));
    final healthColor = healthScore >= 65
        ? ESUNColors.success
        : healthScore >= 50
            ? ESUNColors.warning
            : Colors.red;

    // Keep health data in sync with chat notifier
    ref.listen(aaDataProvider.select((data) => (data.healthScore, data.healthLabel)), (_, next) {
      ref.read(cfoChatProvider.notifier).updateHealthData(
        next.$1,
        next.$2,
      );
    });

    // Auto-scroll when new messages arrive
    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [healthColor.withOpacity(0.8), healthColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: healthColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: ESUNSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KANTA'),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Health $healthScore · $healthLabel',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: healthColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
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
                  // Clear local cache, then parallel refresh
                  ref.read(cacheInterceptorProvider).clear();
                  await Future.wait([
                    ref.read(cfoServiceProvider).refreshData(),
                    ref.read(cfoChatProvider.notifier).loadSummary(),
                  ]);
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
          // Health profile banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md, vertical: ESUNSpacing.xs),
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  healthColor.withOpacity(0.12),
                  healthColor.withOpacity(0.04),
                ],
              ),
              borderRadius: ESUNRadius.lgRadius,
              border: Border.all(color: healthColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    healthScore >= 65 ? Icons.trending_up_rounded : Icons.support_agent_rounded,
                    size: 16,
                    color: healthColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    healthScore >= 80
                        ? 'Wealth Builder — Portfolio optimization & long-term growth'
                        : healthScore >= 65
                            ? 'Growth Mode — Investment growth & surplus optimization'
                            : healthScore >= 50
                                ? 'Recovery Mode — Building savings & improving habits'
                                : 'Stability Mode — Reducing spending & creating safety nets',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: healthColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

          // Quick suggestions — collapsible chips
          if (chatState.messages.length <= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md, vertical: ESUNSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _suggestionsExpanded = !_suggestionsExpanded),
                    child: Row(
                      children: [
                        Text(
                          'Suggestions',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: ESUNColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _suggestionsExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            size: 18,
                            color: ESUNColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_suggestionsExpanded
                            ? _quickSuggestions
                            : _quickSuggestions.take(2).toList())
                        .map((suggestion) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendMessage(suggestion),
                          borderRadius: ESUNRadius.fullRadius,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: ESUNColors.primary.withOpacity(0.06),
                              borderRadius: ESUNRadius.fullRadius,
                              border: Border.all(color: ESUNColors.primary.withOpacity(0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  healthScore >= 65 ? Icons.rocket_launch_outlined : Icons.lightbulb_outline,
                                  size: 14,
                                  color: ESUNColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  suggestion,
                                  style: ESUNTypography.labelSmall.copyWith(
                                    color: ESUNColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: ESUNSpacing.md,
              right: ESUNSpacing.md,
              top: ESUNSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + ESUNSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: ESUNColors.divider.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ESUNColors.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ESUNColors.border.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your finances...',
                        hintStyle: ESUNTypography.bodyMedium.copyWith(
                          color: ESUNColors.textTertiary,
                        ),
                        filled: false,
                        border: InputBorder.none,
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
                ),
                const SizedBox(width: ESUNSpacing.sm),
                // Mic button for speech-to-text
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : ESUNColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: _isListening ? null : Border.all(color: ESUNColors.border.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    onPressed: chatState.isLoading
                        ? null
                        : (_isListening ? _stopListening : _startListening),
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.mic_outlined,
                      color: _isListening ? Colors.white : ESUNColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: _isListening ? 'Stop listening' : 'Speak',
                  ),
                ),
                const SizedBox(width: ESUNSpacing.xs),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: ESUNColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ESUNColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: chatState.isLoading 
                        ? null 
                        : () => _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
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
    final aaData = ref.read(aaDataProvider);
    final profileColor = aaData.healthScore >= 65
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [profileColor, profileColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: profileColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2E4A9A), Color(0xFF3B5EC9)],
                          )
                        : null,
                    color: message.isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 6),
                      bottomRight: Radius.circular(message.isUser ? 6 : 20),
                    ),
                    border: message.isUser ? null : Border.all(
                      color: ESUNColors.divider.withOpacity(0.6),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? ESUNColors.primary.withOpacity(0.15)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                // TTS button + timestamp for AI messages
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _speakMessage(message),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: ESUNSpacing.badgeInsets,
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
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: ESUNTypography.labelSmall.copyWith(
                            color: ESUNColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Timestamp for user messages
                if (message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTimestamp(message.timestamp),
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 10, top: 2),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: ESUNColors.primary, size: 16),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  Widget _buildTypingIndicator() {
    final aaData = ref.read(aaDataProvider);
    final profileColor = aaData.healthScore >= 65
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [profileColor.withOpacity(0.8), profileColor],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
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



