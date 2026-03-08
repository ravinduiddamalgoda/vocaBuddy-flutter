import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocabuddy/pages/doctor_home_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:vocabuddy/api/spelling_mistake_api_client.dart';
import 'package:vocabuddy/api/voice_predict_api_client.dart';

// ===================================================================
// COLORS (MATCH PREVIOUS UI)
// ===================================================================
const Color _kAccentColor = Color(0xFFFF9500);
const Color _kAccentSoft = Color(0xFFFFE8CC);
const Color _kTextDark = Color(0xFF2D3748);
const Color _kTextMuted = Color(0xFF718096);
const Color _kBg = Color(0xFFFFFBF5);
const Color _kCard = Colors.white;

// ===================================================================
// MODEL FOR WORD ITEMS
// ===================================================================
class WordItem {
  final String word;
  final String? imageAssetPath;
  final String? imageUrl;
  final String? audioAssetPath;
  final String? audioBase64;

  const WordItem({
    required this.word,
    this.imageAssetPath,
    this.imageUrl,
    this.audioAssetPath,
    this.audioBase64,
  });
}

// ===================================================================
// SCREEN
// ===================================================================
class AntLearningActivity extends StatefulWidget {
  final String? userId;
  final String? sessionId;
  final String? sessionTitle;
  final String? practiceId;
  final List<Map<String, dynamic>>? sessionObjects;

  const AntLearningActivity({
    Key? key,
    this.userId,
    this.sessionId,
    this.sessionTitle,
    this.practiceId,
    this.sessionObjects,
  }) : super(key: key);

  @override
  State<AntLearningActivity> createState() => _AntLearningActivityState();
}

class _AntLearningActivityState extends State<AntLearningActivity>
    with TickerProviderStateMixin {
  static const Map<String, String> _romanToSinhalaWordMap = {
    'uura': 'ඌරා',
    'samanalaya': 'සමනලයා',
    'makuluwa': 'මකුළුවා',
    'wandura': 'වඳුරා',
    'rambutan': 'රඹුටන්',
    'carrot': 'කැරට්',
    'aba': 'අඹ',
  };

  bool _showCorrectFeedback = false;
  bool _showTryAgainFeedback = false;
  bool _isWordUnavailable = false;
  bool _isRecording = false;
  bool _isPredicting = false;
  Map<String, dynamic>? _lastPrediction;
  Map<String, dynamic>? _lastSpellingMistakeResponse;
  String? _lastRecordedAudioPath;
  final Map<int, String> _resultStatusByIndex = {};

  late final AnimationController _pulseController;
  late final AudioPlayer _player;
  final AudioRecorder _recorder = AudioRecorder();
  final VoicePredictApiClient _voicePredictApiClient = VoicePredictApiClient();
  final SpellingMistakeApiClient _spellingMistakeApiClient =
      SpellingMistakeApiClient();

  static const List<WordItem> _fallbackWords = [
    WordItem(
      word: "සමනලයා",
      imageAssetPath: "assets/photos/samanalaya.png",
      audioAssetPath: "TestVoice/samanalaya.mp3",
    ),
    WordItem(
      word: "ඌරා",
      imageAssetPath: "assets/photos/pig.png",
      audioAssetPath: "TestVoice/ura.mp3",
    ),
    WordItem(
      word: "අඹ",
      imageAssetPath: "assets/photos/mango.png",
      audioAssetPath: "TestVoice/aba.mp3",
    ),
  ];
  late List<WordItem> _words;

  int _currentIndex = 0;

  WordItem get _currentWord => _words[_currentIndex];

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _words = _buildWordsFromSession(widget.sessionObjects);
    _savePracticeProgress();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  List<WordItem> _buildWordsFromSession(List<Map<String, dynamic>>? objects) {
    if (objects == null || objects.isEmpty) {
      return List<WordItem>.from(_fallbackWords);
    }

    final words = objects
        .map((item) {
          final word = (item['word'] ?? '').toString().trim();
          if (word.isEmpty) {
            return null;
          }

          final selectedImageUrl = (item['selected_image_url'] ?? '')
              .toString()
              .trim();
          final base64Audio = (item['audio_base64'] ?? '').toString().trim();

          return WordItem(
            word: word,
            imageUrl: selectedImageUrl.isEmpty ? null : selectedImageUrl,
            audioBase64: base64Audio.isEmpty ? null : base64Audio,
          );
        })
        .whereType<WordItem>()
        .toList();

    if (words.isEmpty) {
      return List<WordItem>.from(_fallbackWords);
    }
    return words;
  }

  String _sanitizeBase64Audio(String audioBase64) {
    var cleaned = audioBase64.trim();
    if (cleaned.startsWith('data:')) {
      final commaIndex = cleaned.indexOf(',');
      if (commaIndex >= 0 && commaIndex < cleaned.length - 1) {
        cleaned = cleaned.substring(commaIndex + 1);
      }
    }
    return cleaned.replaceAll(RegExp(r'\s+'), '');
  }

  String _resolveSpellingText(String sourceWord) {
    final trimmed = sourceWord.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final lower = trimmed.toLowerCase();
    return _romanToSinhalaWordMap[lower] ?? trimmed;
  }

  List<Map<String, dynamic>> _buildWordProgressPayload() {
    return List<Map<String, dynamic>>.generate(_words.length, (i) {
      final status = _resultStatusByIndex[i] ?? 'pending';
      return {'index': i, 'word': _words[i].word, 'status': status};
    });
  }

  Future<void> _savePracticeProgress({
    Map<String, dynamic>? attemptPayload,
  }) async {
    final userId = widget.userId;
    final sessionId = widget.sessionId;
    final practiceId = widget.practiceId;
    if (userId == null ||
        sessionId == null ||
        practiceId == null ||
        userId.isEmpty ||
        sessionId.isEmpty ||
        practiceId.isEmpty) {
      return;
    }

    final completedCount = _resultStatusByIndex.length;
    final successCount = _resultStatusByIndex.values
        .where((v) => v == 'success')
        .length;
    final failedCount = _resultStatusByIndex.values
        .where((v) => v == 'wrong')
        .length;
    final unavailableCount = _resultStatusByIndex.values
        .where((v) => v == 'unavailable')
        .length;
    final status = completedCount >= _words.length
        ? 'completed'
        : 'in_progress';

    try {
      final practiceRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .collection('practice')
          .doc(practiceId);

      await practiceRef.set({
        'current_index': _currentIndex,
        'session_id': sessionId,
        'session_title': widget.sessionTitle ?? '',
        'total_words': _words.length,
        'completed_count': completedCount,
        'success_count': successCount,
        'failed_count': failedCount,
        'unavailable_count': unavailableCount,
        'status': status,
        'word_progress': _buildWordProgressPayload(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (attemptPayload != null) {
        await practiceRef.collection('attempts').add({
          'session_id': sessionId,
          'practice_id': practiceId,
          ...attemptPayload,
          'created_at': FieldValue.serverTimestamp(),
        });
        await practiceRef.set({
          'attempts_count': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[FIREBASE ERROR][savePracticeProgress] $e');
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      _recorder.stop();
    }
    _recorder.dispose();
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ✅ Listen button plays CURRENT word audio
  Future<void> _handleAudioTap() async {
    if (_isRecording || _isPredicting) {
      return;
    }

    setState(() {
      _isWordUnavailable = false;
      _showCorrectFeedback = false;
      _showTryAgainFeedback = false;
    });

    try {
      await _player.stop();
      final base64Audio = (_currentWord.audioBase64 ?? '').trim();
      if (base64Audio.isNotEmpty) {
        final cleanedBase64 = _sanitizeBase64Audio(base64Audio);
        final bytes = base64Decode(base64.normalize(cleanedBase64));
        await _player.play(BytesSource(bytes));
        return;
      }

      final assetAudio = (_currentWord.audioAssetPath ?? '').trim();
      if (assetAudio.isNotEmpty) {
        await _player.play(AssetSource(assetAudio));
        return;
      }

      throw Exception('No audio found for this item.');
    } catch (e) {
      debugPrint("❌ Audio play error: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Audio not playing: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isPredicting) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to record.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _player.stop();
      final path =
          '${Directory.systemTemp.path}/vocabuddy_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: path,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _lastPrediction = null;
        _lastSpellingMistakeResponse = null;
        _isWordUnavailable = false;
        _showCorrectFeedback = false;
        _showTryAgainFeedback = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _predictFromAudioPath(String audioPath) async {
    if (_isPredicting) {
      return;
    }
    final normalizedPath = audioPath.trim();
    if (normalizedPath.isEmpty) {
      throw Exception('Recorded audio path is empty');
    }

    setState(() {
      _isPredicting = true;
      _lastSpellingMistakeResponse = null;
    });

    try {
      final attemptIndex = _currentIndex;
      final targetWord = _currentWord.word.trim();
      final spellingText = _resolveSpellingText(targetWord);
      _lastRecordedAudioPath = normalizedPath;

      final response = await _voicePredictApiClient.predictVoice(
        audioFilePath: normalizedPath,
        targetWord: targetWord,
      );
      debugPrint('[API RESPONSE][voicePredict] ${jsonEncode(response)}');
      final apiSuccess = response['success'] == true;
      final prediction = (response['prediction'] ?? '').toString().trim();
      final confidence = response['confidence'];
      final apiError = (response['error'] ?? '').toString();
      Map<String, dynamic>? spellingMistakeResponse;

      if (apiSuccess && prediction.toLowerCase() == 'incorrect') {
        try {
          spellingMistakeResponse = await _spellingMistakeApiClient
              .checkSpellingMistake(
                audioFilePath: normalizedPath,
                text: spellingText,
              );
          debugPrint(
            '[API RESPONSE][spellingMistake] ${jsonEncode(spellingMistakeResponse)}',
          );
        } catch (e) {
          debugPrint('[API ERROR][spellingMistake] $e');
        }
      }

      var status = 'wrong';
      var showCorrect = false;
      var showWrong = true;
      var showUnavailable = false;

      if (!apiSuccess) {
        if (apiError.toLowerCase().contains('no model found')) {
          status = 'unavailable';
          showWrong = false;
          showUnavailable = true;
        }
      } else {
        final isCorrect = prediction.toLowerCase() == 'correct';
        status = isCorrect ? 'success' : 'wrong';
        showCorrect = isCorrect;
        showWrong = !isCorrect;
      }

      _resultStatusByIndex[attemptIndex] = status;
      await _savePracticeProgress(
        attemptPayload: {
          'word': targetWord,
          'index': attemptIndex,
          'prediction': prediction,
          'confidence': confidence,
          'status': status,
          'api_success': apiSuccess,
          'api_error': apiError,
          'api_response': response,
          'spelling_text_sent': spellingText,
          'spelling_mistake_response': spellingMistakeResponse,
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _lastPrediction = response;
        _lastSpellingMistakeResponse = spellingMistakeResponse;
        _lastRecordedAudioPath = normalizedPath;
        _isWordUnavailable = showUnavailable;
        _showCorrectFeedback = showCorrect;
        _showTryAgainFeedback = showWrong;
      });

      if (showCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Success'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final attemptIndex = _currentIndex;
      final targetWord = _currentWord.word.trim();
      _resultStatusByIndex[attemptIndex] = 'wrong';
      await _savePracticeProgress(
        attemptPayload: {
          'word': targetWord,
          'index': attemptIndex,
          'prediction': '',
          'confidence': null,
          'status': 'wrong',
          'api_success': false,
          'api_error': e.toString(),
          'api_response': null,
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _lastRecordedAudioPath = normalizedPath;
        _lastSpellingMistakeResponse = null;
        _isWordUnavailable = false;
        _showCorrectFeedback = false;
        _showTryAgainFeedback = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  Future<void> _stopRecordingAndPredict() async {
    if (!_isRecording || _isPredicting) {
      return;
    }

    setState(() {
      _isRecording = false;
    });

    try {
      final audioPath = await _recorder.stop();
      if (audioPath == null || audioPath.trim().isEmpty) {
        throw Exception('Recorded audio path is empty');
      }
      await _predictFromAudioPath(audioPath);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleManualUploadTap() async {
    if (_isRecording || _isPredicting) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['wav'],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedPath = (result.files.single.path ?? '').trim();
      if (selectedPath.isEmpty) {
        throw Exception('Selected file path is empty');
      }
      if (!selectedPath.toLowerCase().endsWith('.wav')) {
        throw Exception('Please upload a .wav file');
      }

      await _predictFromAudioPath(selectedPath);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReplayRecordedAudioTap() async {
    if (_isRecording || _isPredicting) {
      return;
    }

    final path = (_lastRecordedAudioPath ?? '').trim();
    if (path.isEmpty) {
      return;
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Recorded file not found.');
      }

      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio not playing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSaveRecordedAudioTap() async {
    if (_isRecording || _isPredicting) {
      return;
    }

    final sourcePath = (_lastRecordedAudioPath ?? '').trim();
    if (sourcePath.isEmpty) {
      return;
    }

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Recorded file not found.');
      }
      final wavBytes = await sourceFile.readAsBytes();
      if (wavBytes.isEmpty) {
        throw Exception('Recorded file is empty.');
      }

      final word = _currentWord.word.trim().isEmpty
          ? 'recording'
          : _currentWord.word.trim();
      final safeWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final now = DateTime.now();
      final suggestedName = '${safeWord}_${now.millisecondsSinceEpoch}.wav';

      final selectedSavePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save WAV file',
        fileName: suggestedName,
        bytes: wavBytes,
        type: FileType.custom,
        allowedExtensions: const ['wav'],
      );

      if (selectedSavePath == null) {
        return;
      }

      if (!mounted) {
        return;
      }
      final location = selectedSavePath.trim();
      final successText = location.isEmpty
          ? 'Saved WAV successfully'
          : 'Saved WAV: $location';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleMicTap() {
    if (_isRecording) {
      _stopRecordingAndPredict();
      return;
    }
    _startRecording();
  }

  void _handleMicLongPressStart() {
    _startRecording();
  }

  void _handleMicLongPressEnd() {
    _stopRecordingAndPredict();
  }

  // ✅ Previous word
  Future<void> _prevWord() async {
    await _player.stop();
    setState(() {
      _isWordUnavailable = false;
      _showCorrectFeedback = false;
      _showTryAgainFeedback = false;
      _lastSpellingMistakeResponse = null;
      _currentIndex = (_currentIndex - 1 + _words.length) % _words.length;
    });
    await _savePracticeProgress();
  }

  // ✅ Next word
  Future<void> _nextWord() async {
    await _player.stop();
    setState(() {
      _isWordUnavailable = false;
      _showCorrectFeedback = false;
      _showTryAgainFeedback = false;
      _lastSpellingMistakeResponse = null;
      _currentIndex = (_currentIndex + 1) % _words.length;
    });
    await _savePracticeProgress();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        scaffoldBackgroundColor: _kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _kBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          elevation: 0.6,
          shadowColor: Colors.black.withOpacity(0.06),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            "Practice",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: _kTextDark,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: _kTextDark),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isSmall = w < 360;
            final isTablet = w >= 600;

            final scale = (w / 390).clamp(0.90, 1.18);
            final horizontal = isTablet ? 32.0 : (isSmall ? 16.0 : 22.0);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: 18 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(scale: scale),
                    SizedBox(height: 18 * scale),

                    // ✅ Word Image Card with side arrows
                    _WordImageCardWithArrows(
                      scale: scale,
                      imageAssetPath: _currentWord.imageAssetPath,
                      imageUrl: _currentWord.imageUrl,
                      onPrev: _prevWord,
                      onNext: _nextWord,
                    ),

                    SizedBox(height: 18 * scale),

                    // ✅ Word Label (updates automatically)
                    Center(
                      child: _WordLabel(scale: scale, word: _currentWord.word),
                    ),

                    SizedBox(height: 20 * scale),

                    _ActionButtons(
                      scale: scale,
                      pulseController: _pulseController,
                      onAudioTap: _handleAudioTap,
                      onMicTap: _handleMicTap,
                      onManualUploadTap: _handleManualUploadTap,
                      onMicLongPressStart: _handleMicLongPressStart,
                      onMicLongPressEnd: _handleMicLongPressEnd,
                      isRecording: _isRecording,
                      isPredicting: _isPredicting,
                    ),

                    SizedBox(height: 18 * scale),

                    _FeedbackSection(
                      scale: scale,
                      showCorrect: _showCorrectFeedback,
                      showTryAgain: _showTryAgainFeedback,
                      isWordUnavailable: _isWordUnavailable,
                      isRecording: _isRecording,
                      isPredicting: _isPredicting,
                      prediction: _lastPrediction,
                      spellingMistakeResponse: _lastSpellingMistakeResponse,
                      canReplayRecordedAudio: (_lastRecordedAudioPath ?? '')
                          .trim()
                          .isNotEmpty,
                      onReplayRecordedAudioTap: _handleReplayRecordedAudioTap,
                      canSaveRecordedAudio: (_lastRecordedAudioPath ?? '')
                          .trim()
                          .isNotEmpty,
                      onSaveRecordedAudioTap: _handleSaveRecordedAudioTap,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===================================================================
// COMPONENTS
// ===================================================================

class _HeaderCard extends StatelessWidget {
  final double scale;
  const _HeaderCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccentColor, Color(0xFFFFAD33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: _kAccentColor.withOpacity(0.20),
            blurRadius: 20 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54 * scale,
            height: 54 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Icon(
              Icons.mic_rounded,
              color: Colors.white,
              size: 26 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "එහෙනම් අපි පටන් ගමු බබා!",
                  style: GoogleFonts.poppins(
                    fontSize: 16.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  "වචනය හොදින් අසා නිවරිදිව කතා කරන්න උත්සහ කරන්න",
                  style: GoogleFonts.poppins(
                    fontSize: 12.2 * scale,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Image card WITH side arrows
class _WordImageCardWithArrows extends StatelessWidget {
  final double scale;
  final String? imageAssetPath;
  final String? imageUrl;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WordImageCardWithArrows({
    required this.scale,
    this.imageAssetPath,
    this.imageUrl,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: _kAccentSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "පිංතූරය දෙස හොදින් බලන්ඩ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13 * scale,
              color: _kTextMuted,
            ),
          ),
          SizedBox(height: 14 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),

              Container(
                width: 190 * scale,
                height: 190 * scale,
                decoration: BoxDecoration(
                  color: _kAccentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kAccentSoft, width: 5),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(18 * scale),
                    child: () {
                      final url = (imageUrl ?? '').trim();
                      if (url.isNotEmpty) {
                        return Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return Center(
                              child: Text(
                                "🖼️",
                                style: TextStyle(fontSize: 55 * scale),
                              ),
                            );
                          },
                        );
                      }

                      final assetPath = (imageAssetPath ?? '').trim();
                      if (assetPath.isNotEmpty) {
                        return Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return Center(
                              child: Text(
                                "🖼️",
                                style: TextStyle(fontSize: 55 * scale),
                              ),
                            );
                          },
                        );
                      }

                      return Center(
                        child: Text(
                          "🖼️",
                          style: TextStyle(fontSize: 55 * scale),
                        ),
                      );
                    }(),
                  ),
                ),
              ),

              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordLabel extends StatelessWidget {
  final double scale;
  final String word;

  const _WordLabel({required this.scale, required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: _kAccentSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: Text(
        word,
        style: GoogleFonts.poppins(
          fontSize: 30 * scale, // ✅ smaller for Sinhala
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: _kTextDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final double scale;
  final AnimationController pulseController;
  final VoidCallback onAudioTap;
  final VoidCallback onMicTap;
  final VoidCallback onManualUploadTap;
  final VoidCallback onMicLongPressStart;
  final VoidCallback onMicLongPressEnd;
  final bool isRecording;
  final bool isPredicting;

  const _ActionButtons({
    required this.scale,
    required this.pulseController,
    required this.onAudioTap,
    required this.onMicTap,
    required this.onManualUploadTap,
    required this.onMicLongPressStart,
    required this.onMicLongPressEnd,
    required this.isRecording,
    required this.isPredicting,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = 64.0 * scale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleActionButton(
          scale: scale,
          size: btnSize,
          label: "වචනය අසන්න",
          icon: Icons.volume_up_rounded,
          color: _kAccentColor,
          onTap: onAudioTap,
          pulseController: pulseController,
        ),
        SizedBox(width: 18 * scale),
        _CircleActionButton(
          scale: scale,
          size: btnSize,
          label: isPredicting
              ? "පරීක්ෂා කරමින්..."
              : (isRecording ? "පටිගත වෙමින්..." : "කතා කරන්න"),
          icon: isPredicting
              ? Icons.hourglass_top_rounded
              : (isRecording ? Icons.stop_rounded : Icons.mic_rounded),
          color: _kTextDark,
          onTap: isPredicting ? () {} : onMicTap,
          onLongPressStart: isPredicting ? null : onMicLongPressStart,
          onLongPressEnd: isPredicting ? null : onMicLongPressEnd,
          pulseController: pulseController,
        ),
        SizedBox(width: 18 * scale),
        _CircleActionButton(
          scale: scale,
          size: btnSize,
          label: "Upload (.wav)",
          icon: Icons.upload_file_rounded,
          color: const Color(0xFF2563EB),
          onTap: isPredicting || isRecording ? () {} : onManualUploadTap,
          pulseController: pulseController,
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final double scale;
  final double size;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final AnimationController pulseController;

  const _CircleActionButton({
    required this.scale,
    required this.size,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, child) {
            final s = 1 + (pulseController.value * 0.03);
            return Transform.scale(scale: s, child: child);
          },
          child: GestureDetector(
            onLongPressStart: onLongPressStart == null
                ? null
                : (_) => onLongPressStart!(),
            onLongPressEnd: onLongPressEnd == null
                ? null
                : (_) => onLongPressEnd!(),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 16 * scale,
                      offset: Offset(0, 10 * scale),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28 * scale),
              ),
            ),
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5 * scale,
            fontWeight: FontWeight.w600,
            color: _kTextMuted,
          ),
        ),
      ],
    );
  }
}

// ✅ Keep your feedback widgets as-is
class _FeedbackSection extends StatelessWidget {
  final double scale;
  final bool showCorrect;
  final bool showTryAgain;
  final bool isWordUnavailable;
  final bool isRecording;
  final bool isPredicting;
  final Map<String, dynamic>? prediction;
  final Map<String, dynamic>? spellingMistakeResponse;
  final bool canReplayRecordedAudio;
  final VoidCallback onReplayRecordedAudioTap;
  final bool canSaveRecordedAudio;
  final VoidCallback onSaveRecordedAudioTap;

  const _FeedbackSection({
    required this.scale,
    required this.showCorrect,
    required this.showTryAgain,
    required this.isWordUnavailable,
    required this.isRecording,
    required this.isPredicting,
    required this.prediction,
    required this.spellingMistakeResponse,
    required this.canReplayRecordedAudio,
    required this.onReplayRecordedAudioTap,
    required this.canSaveRecordedAudio,
    required this.onSaveRecordedAudioTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    if (isRecording) {
      bg = const Color(0xFFFFF4E6);
      fg = const Color(0xFFB45309);
      text = 'Recording... tap/hold mic again to stop.';
    } else if (isPredicting) {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      text = 'Checking pronunciation...';
    } else if (isWordUnavailable) {
      bg = const Color(0xFFFFF4E6);
      fg = const Color(0xFFB45309);
      text = 'Word not availabe';
    } else if (showCorrect) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      text = 'Success';
    } else if (showTryAgain) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      text = 'Wrong';
    } else {
      return const SizedBox.shrink();
    }

    final canShowReplayAction =
        !isRecording &&
        !isPredicting &&
        canReplayRecordedAudio &&
        (isWordUnavailable || showCorrect || showTryAgain);
    final canShowSaveAction =
        !isRecording &&
        !isPredicting &&
        canSaveRecordedAudio &&
        (isWordUnavailable || showCorrect || showTryAgain);
    final typedText = (spellingMistakeResponse?['typed_text'] ?? '')
        .toString()
        .trim();
    final voiceText = (spellingMistakeResponse?['voice_text'] ?? '')
        .toString()
        .trim();
    final rawDifferences = spellingMistakeResponse?['differences'];
    final differences = rawDifferences is List
        ? rawDifferences
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final canShowSpellingDetails =
        !isRecording &&
        !isPredicting &&
        showTryAgain &&
        spellingMistakeResponse != null &&
        (typedText.isNotEmpty ||
            voiceText.isNotEmpty ||
            differences.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: canShowReplayAction
                      ? TextAlign.left
                      : TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5 * scale,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              if (canShowReplayAction) ...[
                SizedBox(width: 8 * scale),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onReplayRecordedAudioTap,
                  child: Container(
                    width: 34 * scale,
                    height: 34 * scale,
                    decoration: BoxDecoration(
                      color: fg.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: fg,
                      size: 20 * scale,
                    ),
                  ),
                ),
              ],
              if (canShowSaveAction) ...[
                SizedBox(width: 8 * scale),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onSaveRecordedAudioTap,
                  child: Container(
                    width: 34 * scale,
                    height: 34 * scale,
                    decoration: BoxDecoration(
                      color: fg.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: fg,
                      size: 18 * scale,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (canShowSpellingDetails) ...[
            SizedBox(height: 10 * scale),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10 * scale),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (typedText.isNotEmpty)
                    Text(
                      'Typed: $typedText',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5 * scale,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  if (voiceText.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4 * scale),
                      child: Text(
                        'Voice: $voiceText',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5 * scale,
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                    ),
                  if (differences.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4 * scale),
                      child: Text(
                        'Differences: ${differences.join(', ')}',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5 * scale,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
