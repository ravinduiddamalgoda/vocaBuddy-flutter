// activity_review_page.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ActivityAssignmentConfirmationPage.dart';

class ActivityReviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedChildren;
  final String activityType;
  final String prompt;
  final Map<String, dynamic> apiPreview;

  const ActivityReviewPage({
    Key? key,
    required this.selectedChildren,
    required this.activityType,
    required this.prompt,
    required this.apiPreview,
  }) : super(key: key);

  @override
  State<ActivityReviewPage> createState() => _ActivityReviewPageState();
}

class _ActivityReviewPageState extends State<ActivityReviewPage> {
  bool _isGenerating = true;
  bool _isRegenerating = false;
  bool _isEditingPrompt = false;
  final TextEditingController _promptController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  List<String> _getWords() {
    final preview = widget.apiPreview ?? {};
    final items = (preview["items"] as List? ?? []);
    return items
        .map((e) => (e["text"] ?? "").toString())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _generatedActivity = {};
  List<String> _apiWords = [];

  @override
  void initState() {
    super.initState();
    _promptController.text = widget.prompt;
    _loadFromPreview();
  }

  void _loadFromPreview() {
    final items = (widget.apiPreview["items"] as List?) ?? [];
    final words = items.map((e) => e["text"].toString()).toList();
    final firstWord = words.isNotEmpty ? words.first : "No word found";

    setState(() {
      _apiWords = words;
      _generatedActivity = {
        'content': firstWord,
        'type': 'word',
        'imageUrl': 'https://picsum.photos/id/1/200/300', // keep placeholder for now
        'audioUrl': '', // later
        'targetSound': widget.apiPreview["target_letter"] ?? '',
        'missing_count': widget.apiPreview["missing_count"] ?? 0,
        'returned_count': widget.apiPreview["returned_count"] ?? items.length,
        'requested_count': widget.apiPreview["requested_count"] ?? 0,
        'can_generate': widget.apiPreview["can_generate"] ?? false,
      };
      _isGenerating = false;
    });
  }

  void _regenerateActivity() async {
    setState(() {
      _isRegenerating = true;
      _isEditingPrompt = false;
    });

    // Simulate API call with updated prompt
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      bool isLevel1 = widget.activityType.contains('01');

      _generatedActivity = {
        'content': isLevel1 ? 'Turtle' : 'The turtle walks slowly on the sand',
        'type': isLevel1 ? 'word' : 'sentence',
        'imageUrl': 'https://picsum.photos/id/1/200/300',
        'audioUrl': 'https://example.com/turtle_audio.mp3',
        'targetSound': '/t/',
      };
      _isRegenerating = false;
    });
  }

  Future<void> _playAudio() async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingAudio = false;
      });
    } else {
      // In production, use: await _audioPlayer.play(UrlSource(_generatedActivity['audioUrl']));
      setState(() {
        _isPlayingAudio = true;
      });

      // Simulate audio duration
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: _isGenerating
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF9800),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generating activity...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Review Activity',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please confirm this activity is use full for this child',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 32),

              // Edit Prompt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Color(0xFFFF9800),
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Your Prompt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isEditingPrompt = !_isEditingPrompt;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isEditingPrompt ? Icons.close : Icons.edit,
                                  size: 16,
                                  color: const Color(0xFFFF9800),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isEditingPrompt ? 'Cancel' : 'Edit',
                                  style: const TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isEditingPrompt) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _promptController,
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Edit your prompt...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _regenerateActivity,
                            borderRadius: BorderRadius.circular(14),
                            child: const Center(
                              child: Text(
                                'Update & Regenerate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Text(
                        _promptController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_isRegenerating)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    margin: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFFF9800),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Regenerating activity...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Main Activity Card (UPDATED TO PAGEVIEW)
                Builder(
                  builder: (context) {
                    final words = _apiWords.isNotEmpty
                        ? _apiWords
                        : [(_generatedActivity['content'] ?? "No word found").toString()];

                    return SizedBox(
                      height: 560, // enough for image + word + buttons
                      child: PageView.builder(
                        itemCount: words.length,
                        controller: PageController(viewportFraction: 0.92),
                        itemBuilder: (context, index) {
                          final word = words[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Image Section (same for now)
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          height: 320,
                                          color: const Color(0xFFF8FAFC),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 140,
                                                  height: 140,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFF4E6),
                                                    borderRadius: BorderRadius.circular(24),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(24),
                                                    child: Image.network(
                                                      _generatedActivity['imageUrl'] ??
                                                          "https://picsum.photos/200/300",
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                const Text('Activity Image'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Target sound badge (same for now)
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9800),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF9800).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.graphic_eq,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _generatedActivity['targetSound'] ?? "/?/",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Content and Audio Section (UPDATED TO FIX OVERFLOW)
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(28),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // ✅ Word changes per swipe
                                          Text(
                                            word,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF334155),
                                              height: 1.3,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Type Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF4E6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _generatedActivity['type'] == 'word'
                                                  ? 'Single Word'
                                                  : 'Sentence',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFFF9800),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Play Audio Button (same for now)
                                          InkWell(
                                            onTap: _playAudio,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 18,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFFF9800).withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _isPlayingAudio
                                                        ? Icons.pause_circle_filled
                                                        : Icons.play_circle_filled,
                                                    color: Colors.white,
                                                    size: 32,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    _isPlayingAudio ? 'Playing...' : 'Play Voice',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          // Optional small indicator
                                          Text(
                                            "${index + 1} / ${words.length}  •  Swipe",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Accept Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityAssignmentConfirmationPage(
                              selectedChildren: widget.selectedChildren,
                              activity: _generatedActivity,
                              activityType: widget.activityType,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Accept & Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
