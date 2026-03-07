// activity_review_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vocabuddy/api/activity_image_api_client.dart';

class ActivityReviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedChildren;
  final String activityType;
  final String prompt;
  final Map<String, dynamic> apiPreview;
  final String? firebaseChildId;
  final String? firebaseSessionId;

  const ActivityReviewPage({
    Key? key,
    required this.selectedChildren,
    required this.activityType,
    required this.prompt,
    required this.apiPreview,
    this.firebaseChildId,
    this.firebaseSessionId,
  }) : super(key: key);

  @override
  State<ActivityReviewPage> createState() => _ActivityReviewPageState();
}

class _ActivityReviewPageState extends State<ActivityReviewPage> {
  bool _isGenerating = true;
  bool _isRegenerating = false;
  bool _isEditingPrompt = false;
  bool _isSavingSelection = false;
  bool _isLoadingImages = false;
  final TextEditingController _promptController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ActivityImageApiClient _imageApiClient = ActivityImageApiClient();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  bool _isPlayingAudio = false;
  String? _playingAudioKey;
  String? _loadError;

  Map<String, dynamic> _generatedActivity = {};
  List<String> _apiWords = [];
  List<Map<String, dynamic>> _sessionObjects = [];
  final Map<String, List<String>> _imageOptionsByDocId = {};
  final Map<String, int> _selectedImageIndexByDocId = {};

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlayingAudio = state == PlayerState.playing;
      });
    });
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlayingAudio = false;
        _playingAudioKey = null;
      });
    });

    _promptController.text = widget.prompt;
    final hasFirebaseSession =
        (widget.firebaseChildId?.isNotEmpty ?? false) &&
        (widget.firebaseSessionId?.isNotEmpty ?? false);
    if (hasFirebaseSession) {
      _loadFromFirebaseSession();
    } else {
      _loadFromPreview();
    }
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
        'imageUrl':
            'https://picsum.photos/id/1/200/300', // keep placeholder for now
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

  Future<void> _loadFromFirebaseSession() async {
    final childId = widget.firebaseChildId;
    final sessionId = widget.firebaseSessionId;
    if (childId == null || sessionId == null) {
      _loadFromPreview();
      return;
    }

    try {
      final sessionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .collection('sessions')
          .doc(sessionId);

      final sessionSnapshot = await sessionRef.get();
      final objectsSnapshot = await sessionRef
          .collection('objects')
          .orderBy('index')
          .get();

      final objects = objectsSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['__doc_id'] = doc.id;
        return data;
      }).toList();
      final words = objects
          .map((item) => (item['word'] ?? '').toString().trim())
          .where((word) => word.isNotEmpty)
          .toList();
      final firstWord = words.isNotEmpty ? words.first : "No word found";
      final sessionData = sessionSnapshot.data() ?? <String, dynamic>{};
      final request = (sessionData['request'] is Map)
          ? Map<String, dynamic>.from(sessionData['request'] as Map)
          : <String, dynamic>{};
      final requestLetter = (request['letter'] ?? widget.prompt).toString();

      if (!mounted) {
        return;
      }

      setState(() {
        _sessionObjects = objects;
        _apiWords = words;
        _generatedActivity = {
          'content': firstWord,
          'type': 'word',
          'imageUrl': 'https://picsum.photos/id/1/200/300',
          'audioUrl': '',
          'targetSound': requestLetter,
          'missing_count': 0,
          'returned_count': words.length,
          'requested_count': words.length,
          'can_generate': true,
        };
        _isGenerating = false;
        _loadError = null;
      });

      await _loadImagesForObjects(objects);
    } on FirebaseException catch (e) {
      debugPrint(
        '[FIREBASE ERROR][ActivityReviewPage.loadSession] code=${e.code} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = 'Failed to load session objects [${e.code}]';
        _isGenerating = false;
      });
    } catch (e) {
      debugPrint('[ERROR][ActivityReviewPage.loadSession] $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = 'Failed to load session objects: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _loadImagesForObjects(List<Map<String, dynamic>> objects) async {
    if (objects.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isLoadingImages = true;
    });

    try {
      for (final object in objects) {
        final docId = (object['__doc_id'] ?? '').toString();
        final word = (object['word'] ?? '').toString().trim();
        if (docId.isEmpty || word.isEmpty) {
          continue;
        }

        try {
          final images = await _imageApiClient.fetchImagesForWord(word: word);
          if (images.isEmpty) {
            continue;
          }

          final existingSelectedImage = (object['selected_image_url'] ?? '')
              .toString()
              .trim();
          var selectedIndex = 0;
          if (existingSelectedImage.isNotEmpty) {
            final index = images.indexOf(existingSelectedImage);
            if (index >= 0) {
              selectedIndex = index;
            }
          }

          if (!mounted) {
            return;
          }
          setState(() {
            _imageOptionsByDocId[docId] = images;
            _selectedImageIndexByDocId[docId] = selectedIndex;
          });
        } catch (e) {
          debugPrint('[API ERROR][image][word=$word] $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  String? _selectedImageUrlForDoc(String docId) {
    final options = _imageOptionsByDocId[docId];
    if (options == null || options.isEmpty) {
      return null;
    }
    final index = _selectedImageIndexByDocId[docId] ?? 0;
    if (index < 0 || index >= options.length) {
      return options.first;
    }
    return options[index];
  }

  void _onChangeImage(String docId) {
    final options = _imageOptionsByDocId[docId];
    if (options == null || options.length <= 1) {
      return;
    }
    final current = _selectedImageIndexByDocId[docId] ?? 0;
    final next = (current + 1) % options.length;
    setState(() {
      _selectedImageIndexByDocId[docId] = next;
    });
  }

  Future<void> _acceptAndContinue() async {
    final childId = widget.firebaseChildId;
    final sessionId = widget.firebaseSessionId;

    // Fallback behavior for legacy preview-only flow
    if (childId == null ||
        sessionId == null ||
        childId.isEmpty ||
        sessionId.isEmpty ||
        _sessionObjects.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Firebase session found to save selected images.'),
        ),
      );
      return;
    }

    setState(() {
      _isSavingSelection = true;
    });

    try {
      final sessionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .collection('sessions')
          .doc(sessionId);

      final batch = FirebaseFirestore.instance.batch();
      for (final object in _sessionObjects) {
        final docId = (object['__doc_id'] ?? '').toString();
        if (docId.isEmpty) {
          continue;
        }

        final selectedImageUrl = _selectedImageUrlForDoc(docId);
        if (selectedImageUrl == null || selectedImageUrl.isEmpty) {
          continue;
        }

        batch.update(sessionRef.collection('objects').doc(docId), {
          'selected_image_url': selectedImageUrl,
          'selected_image_index': _selectedImageIndexByDocId[docId] ?? 0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity saved successfully.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on FirebaseException catch (e) {
      debugPrint(
        '[FIREBASE ERROR][ActivityReviewPage.saveSelectedImages] code=${e.code} message=${e.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase error [${e.code}]: ${e.message ?? e.toString()}',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      debugPrint('[ERROR][ActivityReviewPage.saveSelectedImages] $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save selected images: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSelection = false;
        });
      }
    }
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

  Future<void> _playAudio({
    required String audioBase64,
    required String audioKey,
  }) async {
    final rawAudio = audioBase64.trim();
    if (rawAudio.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio is not available for this word.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    try {
      if (_isPlayingAudio && _playingAudioKey == audioKey) {
        await _audioPlayer.pause();
        if (mounted) {
          setState(() {
            _isPlayingAudio = false;
          });
        }
        return;
      }

      final cleanedBase64 = _sanitizeBase64Audio(rawAudio);
      final normalizedBase64 = base64.normalize(cleanedBase64);
      final audioBytes = base64Decode(normalizedBase64);
      if (audioBytes.isEmpty) {
        throw const FormatException('Decoded audio bytes are empty');
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(audioBytes));

      if (mounted) {
        setState(() {
          _isPlayingAudio = true;
          _playingAudioKey = audioKey;
        });
      }
    } on FormatException catch (e) {
      debugPrint('[AUDIO ERROR][base64] $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid audio format received from server.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      debugPrint('[AUDIO ERROR][playback] $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to play audio: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
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
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF64748B),
              size: 20,
            ),
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
                      style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 32),

                    if (_loadError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _loadError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_sessionObjects.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          'Loaded ${_sessionObjects.length} session objects from Firebase',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isLoadingImages) ...[
                      const LinearProgressIndicator(
                        color: Color(0xFFFF9800),
                        backgroundColor: Color(0xFFFFF4E6),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Loading images for each word...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                                        _isEditingPrompt
                                            ? Icons.close
                                            : Icons.edit,
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
                                  colors: [
                                    Color(0xFFFF9800),
                                    Color(0xFFFF6F00),
                                  ],
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
                              : [
                                  (_generatedActivity['content'] ??
                                          "No word found")
                                      .toString(),
                                ];
                          final objectItems = _sessionObjects.isNotEmpty
                              ? _sessionObjects
                              : words
                                    .map(
                                      (word) => <String, dynamic>{'word': word},
                                    )
                                    .toList();

                          return SizedBox(
                            height: 560, // enough for image + word + buttons
                            child: PageView.builder(
                              itemCount: objectItems.length,
                              controller: PageController(
                                viewportFraction: 0.92,
                              ),
                              itemBuilder: (context, index) {
                                final currentObject = objectItems[index];
                                final docId = (currentObject['__doc_id'] ?? '')
                                    .toString()
                                    .trim();
                                final word =
                                    (currentObject['word'] ?? '')
                                        .toString()
                                        .trim()
                                        .isEmpty
                                    ? 'No word found'
                                    : (currentObject['word'] ?? '').toString();
                                final audioBase64 =
                                    (currentObject['audio_base64'] ?? '')
                                        .toString();
                                final hasAudio = audioBase64.trim().isNotEmpty;
                                final audioKey = docId.isEmpty
                                    ? 'preview_$index'
                                    : docId;
                                final isCurrentAudioPlaying =
                                    _isPlayingAudio &&
                                    _playingAudioKey == audioKey;
                                final selectedImageUrl = docId.isEmpty
                                    ? null
                                    : _selectedImageUrlForDoc(docId);
                                final imageOptions = docId.isEmpty
                                    ? <String>[]
                                    : (_imageOptionsByDocId[docId] ??
                                          <String>[]);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
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
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(24),
                                                  ),
                                              child: Container(
                                                width: double.infinity,
                                                height: 320,
                                                color: const Color(0xFFF8FAFC),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        width: 140,
                                                        height: 140,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFFFF4E6,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                24,
                                                              ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                24,
                                                              ),
                                                          child: Image.network(
                                                            selectedImageUrl ??
                                                                _generatedActivity['imageUrl'] ??
                                                                "https://picsum.photos/200/300",
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      const Text(
                                                        'Activity Image',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            if (docId.isNotEmpty &&
                                                imageOptions.isNotEmpty)
                                              Positioned(
                                                top: 16,
                                                left: 16,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _onChangeImage(docId),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.12,
                                                              ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        Icon(
                                                          Icons.change_circle,
                                                          size: 18,
                                                          color: Color(
                                                            0xFFFF9800,
                                                          ),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          'Change',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                              0xFF334155,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Target sound badge
                                            Positioned(
                                              top: 16,
                                              right: 16,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFF9800,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFFFF9800,
                                                      ).withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.graphic_eq,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      _generatedActivity['targetSound'] ??
                                                          "/?/",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFFF4E6,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _generatedActivity['type'] ==
                                                            'word'
                                                        ? 'Single Word'
                                                        : 'Sentence',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFFFF9800),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 24),

                                                // Play Audio Button (same for now)
                                                InkWell(
                                                  onTap: () => _playAudio(
                                                    audioBase64: audioBase64,
                                                    audioKey: audioKey,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 32,
                                                          vertical: 18,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFFFF9800),
                                                              Color(0xFFFF6F00),
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFFFF9800,
                                                          ).withOpacity(0.4),
                                                          blurRadius: 20,
                                                          offset: const Offset(
                                                            0,
                                                            8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isCurrentAudioPlaying
                                                              ? Icons
                                                                    .pause_circle_filled
                                                              : Icons
                                                                    .play_circle_filled,
                                                          color: Colors.white,
                                                          size: 32,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          isCurrentAudioPlaying
                                                              ? 'Playing...'
                                                              : 'Play Voice',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 10),

                                                if (_sessionObjects.isNotEmpty)
                                                  Text(
                                                    hasAudio
                                                        ? 'Audio available'
                                                        : 'Audio missing',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: hasAudio
                                                          ? const Color(
                                                              0xFF059669,
                                                            )
                                                          : const Color(
                                                              0xFFDC2626,
                                                            ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),

                                                if (_sessionObjects.isNotEmpty)
                                                  const SizedBox(height: 6),

                                                if (imageOptions.isNotEmpty)
                                                  Text(
                                                    'Image ${(_selectedImageIndexByDocId[docId] ?? 0) + 1}/${imageOptions.length}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),

                                                if (imageOptions.isNotEmpty)
                                                  const SizedBox(height: 6),

                                                // Optional small indicator
                                                Text(
                                                  "${index + 1} / ${objectItems.length}  •  Swipe",
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
                            onTap: _isSavingSelection
                                ? null
                                : _acceptAndContinue,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSavingSelection)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  if (_isSavingSelection)
                                    const SizedBox(width: 10),
                                  Text(
                                    _isSavingSelection
                                        ? 'Saving Selection...'
                                        : 'Accept & Continue',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
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
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
