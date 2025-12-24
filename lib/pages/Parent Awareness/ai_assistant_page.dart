// ai_assistant_page.dart
import 'package:flutter/material.dart';

class AIAssistantPage extends StatefulWidget {
  final Map<String, dynamic> childData;

  const AIAssistantPage({Key? key, required this.childData}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  // Quick question suggestions
  final List<Map<String, String>> _quickQuestions = [
    {
      'icon': '📊',
      'question': 'How is my child progressing?',
    },
    {
      'icon': '🎯',
      'question': 'What areas need improvement?',
    },
    {
      'icon': '💡',
      'question': 'Suggest activities for practice',
    },
    {
      'icon': '📈',
      'question': 'Explain the latest scores',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add({
      'text': 'Hello! I\'m your AI assistant for ${widget.childData['name']}. I can help you understand their progress, suggest activities, and answer questions about their speech development. How can I help you today?',
      'isUser': false,
      'timestamp': DateTime.now(),
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _messages.add({
          'text': _getAIResponse(text),
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAIResponse(String question) {
    final childName = widget.childData['name'];
    final accuracy = widget.childData['accuracy'];
    final sessions = widget.childData['sessions'];
    final totalSessions = widget.childData['totalSessions'];

    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('progress') || lowerQuestion.contains('doing')) {
      return '$childName is showing excellent progress! Their pronunciation accuracy is currently at $accuracy%, and they\'ve completed $sessions out of $totalSessions sessions. They\'re particularly strong with vowel sounds and are making steady improvements in other areas. Keep up the great work! 🎉';
    } else if (lowerQuestion.contains('improve') || lowerQuestion.contains('need') || lowerQuestion.contains('focus')) {
      return 'Based on the latest assessments, $childName would benefit from additional practice with R sounds. Here are some focus areas:\n\n• R sounds: Practice words like "red," "run," "rabbit"\n• Blending exercises for consonant clusters\n• Daily 10-minute practice sessions\n\nWould you like specific activity recommendations?';
    } else if (lowerQuestion.contains('activit') || lowerQuestion.contains('practice') || lowerQuestion.contains('exercise')) {
      return 'Here are some fun activity suggestions for $childName:\n\n🪞 **Mirror Practice**: Have them watch their mouth movements while pronouncing challenging sounds.\n\n🔍 **Sound Scavenger Hunt**: Find objects around the house that start with target sounds.\n\n🎵 **Rhyme Time**: Create rhyming games with target sounds to make practice enjoyable.\n\n📚 **Story Reading**: Read books emphasizing the focus sounds.\n\nWould you like more detailed instructions for any of these?';
    } else if (lowerQuestion.contains('score') || lowerQuestion.contains('result') || lowerQuestion.contains('accuracy')) {
      return 'Here\'s a breakdown of $childName\'s latest scores:\n\n📊 Overall accuracy: $accuracy%\n🎯 Vowel sounds: 85% (Excellent!)\n📈 S sounds: 75% (Good progress)\n📉 R sounds: 60% (Needs focus)\n✨ T sounds: 80% (Very good)\n\nThey completed $sessions out of $totalSessions sessions this period, showing great consistency!';
    } else if (lowerQuestion.contains('how long') || lowerQuestion.contains('time')) {
      return 'The typical therapy timeline varies, but based on $childName\'s current progress at $accuracy% accuracy, here\'s what to expect:\n\n⏱️ Short-term (1-2 months): Focus on targeted sounds\n📅 Medium-term (3-6 months): Consistent improvement across categories\n🎯 Long-term (6-12 months): Achieving 90%+ accuracy\n\nConsistency is key! Daily 10-15 minute practice sessions make a huge difference.';
    } else if (lowerQuestion.contains('help') || lowerQuestion.contains('support')) {
      return 'There are many ways you can support $childName at home:\n\n💬 Practice daily conversations focusing on target sounds\n👂 Listen actively and provide positive reinforcement\n📖 Read together and emphasize pronunciation\n🎮 Make it fun with games and activities\n⏰ Keep practice sessions short (10-15 mins) but consistent\n\nRemember, you\'re doing a great job! Every bit of practice helps.';
    } else if (lowerQuestion.contains('when') || lowerQuestion.contains('schedule')) {
      return 'For $childName, I recommend:\n\n🌅 **Morning sessions** (5-10 mins): Light warm-up exercises\n🏫 **After school** (10-15 mins): Main practice session\n🌙 **Bedtime** (5 mins): Quick review with a story\n\nThey\'ve been completing their sessions well - $sessions out of $totalSessions done! Keep maintaining this consistency.';
    } else if (lowerQuestion.contains('thank') || lowerQuestion.contains('thanks')) {
      return 'You\'re welcome! I\'m always here to help. Remember, you\'re doing an amazing job supporting $childName\'s progress. If you have any other questions, feel free to ask! 😊';
    } else {
      return 'I\'d be happy to help with that! I can discuss:\n\n📊 Progress reports and analytics\n🎯 Activity and exercise suggestions\n📈 Score explanations\n💡 Tips for home practice\n⏰ Session scheduling advice\n\nWhat specific information about $childName would you like to know?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping) _buildTypingIndicator(),

          // Quick Questions (shown at start)
          if (_messages.length <= 1) _buildQuickQuestions(),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Questions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((q) {
              return InkWell(
                onTap: () => _sendMessage(q['question']!),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        q['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        q['question']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF22C55E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: Radius.circular(isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message['text'],
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFF22C55E),
              (value + index * 0.3) % 1.0,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (text) => _sendMessage(text),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _sendMessage(_messageController.text),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF64748B)),
              title: const Text('Clear Conversation'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _messages.add({
                    'text': 'Hello! I\'m your AI assistant for ${widget.childData['name']}. How can I help you today?',
                    'isUser': false,
                    'timestamp': DateTime.now(),
                  });
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF64748B)),
              title: const Text('About AI Assistant'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About AI Assistant'),
        content: const Text(
          'This AI assistant helps you understand your child\'s speech therapy progress, suggests activities, and answers questions about their development.\n\nNote: This is a demo version with simulated responses.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}