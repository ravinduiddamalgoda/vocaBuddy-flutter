import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

/// =======================
/// MAIN SCREEN
/// =======================
class UploadVoiceRecordingsScreen extends StatefulWidget {
  const UploadVoiceRecordingsScreen({super.key});

  @override
  State<UploadVoiceRecordingsScreen> createState() =>
      _UploadVoiceRecordingsScreenState();
}

/// =======================
/// MODELS
/// =======================
class Recording {
  final String id;
  final String name;
  final String audioBase64;
  final String type;
  final DateTime dateAdded;

  Recording({
    required this.id,
    required this.name,
    required this.audioBase64,
    required this.type,
    required this.dateAdded,
  });
}

class Folder {
  final String id;
  final String name;
  final DateTime createdAt;

  Folder({required this.id, required this.name, required this.createdAt});
}

/// =======================
/// HOME PAGE STATE
/// =======================
class _UploadVoiceRecordingsScreenState
    extends State<UploadVoiceRecordingsScreen> {
  Future<void> _createFolderInFirestore(String folderTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    final name = folderTitle.trim();
    if (name.isEmpty) {
      return;
    }
    if (name.contains('/')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder title cannot contain "/"')),
      );
      return;
    }

    final folderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('voice-record')
        .doc(name);

    final existing = await folderRef.get();
    if (existing.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Folder already exists.')));
      return;
    }

    await folderRef.set({
      'name': name,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'correct_count': 0,
      'incorrect_count': 0,
    });
  }

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) {
        final folderController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'නව ෆෝල්ඩරයක් සාදන්න',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: folderController,
            decoration: InputDecoration(
              hintText: 'ෆෝල්ඩර නම ඇතුළත් කරන්න',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: const Color(0xFFFFF3E8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'අවලංගු කරන්න',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final folderName = folderController.text.trim();
                if (folderName.isEmpty) {
                  return;
                }
                Navigator.pop(context);
                await _createFolderInFirestore(folderName);
              },
              child: const Text('සාදන්න'),
            ),
          ],
        );
      },
    );
  }

  void _openFolder(Folder folder, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderDetailPage(
          userId: userId,
          folderId: folder.id,
          folderName: folder.name,
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),

      /// ✅ APP BAR with BACK BUTTON
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3B1F47)),
          onPressed: () => Navigator.pop(context), // ✅ back to previous page
        ),
        centerTitle: true,
        title: const Text(
          "Upload Voice Recordings",
          style: TextStyle(
            color: Color(0xFF3B1F47),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      /// BODY
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER CARD (same theme style)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA726),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'අලුත් වචන එකතු කරන්න !',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A4332),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'සිංහල Interactive Learning Platform',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A6E5A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// FOLDERS LIST
            Expanded(
              child: userId.isEmpty
                  ? Center(
                      child: Text(
                        "User not logged in.",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('voice-record')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6D00),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Failed to load folders.",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        final docs = (snapshot.data?.docs ?? []).toList()
                          ..sort((a, b) {
                            final aDate = _parseDate(a.data()['created_at']);
                            final bDate = _parseDate(b.data()['created_at']);
                            return bDate.compareTo(aDate);
                          });

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              "No folders yet. Create your first folder!",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final name = (data['name'] ?? doc.id).toString();
                            final createdAt = _parseDate(data['created_at']);
                            final correct = (data['correct_count'] is num)
                                ? (data['correct_count'] as num).toInt()
                                : 0;
                            final incorrect = (data['incorrect_count'] is num)
                                ? (data['incorrect_count'] as num).toInt()
                                : 0;
                            final total = correct + incorrect;

                            return _buildFolderCard(
                              Folder(
                                id: doc.id,
                                name: name,
                                createdAt: createdAt,
                              ),
                              totalRecordings: total,
                              userId: userId,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      /// FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewFolder,
        backgroundColor: const Color(0xFFFF6D00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('නව ෆෝල්ඩරය', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFolderCard(
    Folder folder, {
    required int totalRecordings,
    required String userId,
  }) {
    return GestureDetector(
      onTap: () => _openFolder(folder, userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFF3E8), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.folder,
                color: Color(0xFFFF6D00),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B1F47),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$totalRecordings recordings",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFFF6D00),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// FOLDER DETAIL PAGE
/// =======================
class FolderDetailPage extends StatefulWidget {
  final String userId;
  final String folderId;
  final String folderName;

  const FolderDetailPage({
    super.key,
    required this.userId,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  String selectedTab = 'right';
  bool _isUploading = false;
  late final AudioPlayer _audioPlayer;
  String? _playingRecordingId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingRecordingId = null;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _sanitizeBase64(String input) {
    var cleaned = input.trim();
    if (cleaned.startsWith('data:')) {
      final commaIndex = cleaned.indexOf(',');
      if (commaIndex >= 0 && commaIndex < cleaned.length - 1) {
        cleaned = cleaned.substring(commaIndex + 1);
      }
    }
    return cleaned.replaceAll(RegExp(r'\s+'), '');
  }

  Future<void> _playRecording(Recording recording) async {
    try {
      final base64Audio = _sanitizeBase64(recording.audioBase64);
      if (base64Audio.isEmpty) {
        throw Exception('Audio is empty');
      }

      final bytes = base64Decode(base64.normalize(base64Audio));
      if (bytes.isEmpty) {
        throw Exception('Decoded audio is empty');
      }

      var extension = 'wav';
      final dotIndex = recording.name.lastIndexOf('.');
      if (dotIndex > 0 && dotIndex < recording.name.length - 1) {
        extension = recording.name.substring(dotIndex + 1).toLowerCase();
      }

      final tempPath =
          '${Directory.systemTemp.path}/vocabuddy_play_${recording.id}_${DateTime.now().microsecondsSinceEpoch}.$extension';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(tempPath));

      if (!mounted) return;
      setState(() {
        _playingRecordingId = recording.id;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Audio playback failed: $e')));
    }
  }

  Future<void> _pickAudioFile(bool isCorrect) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final type = isCorrect ? 'right' : 'wrong';
    setState(() {
      _isUploading = true;
    });

    try {
      final folderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('voice-record')
          .doc(widget.folderId);

      final batch = FirebaseFirestore.instance.batch();
      var uploadedCount = 0;

      for (final file in result.files) {
        final filePath = (file.path ?? '').trim();
        if (filePath.isEmpty) {
          continue;
        }

        final bytes = await File(filePath).readAsBytes();
        if (bytes.isEmpty) {
          continue;
        }

        final audioBase64 = base64Encode(bytes);
        final recordRef = folderRef.collection('records').doc();
        batch.set(recordRef, {
          'name': file.name,
          'audio_base64': audioBase64,
          'type': type,
          'size_bytes': bytes.length,
          'created_at': FieldValue.serverTimestamp(),
        });
        uploadedCount++;
      }

      if (uploadedCount == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid audio files selected.')),
        );
        return;
      }

      final countField = type == 'right' ? 'correct_count' : 'incorrect_count';
      batch.set(folderRef, {
        countField: FieldValue.increment(uploadedCount),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded $uploadedCount recording(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),

      /// ✅ BACK BUTTON
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3B1F47)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.folderName,
          style: const TextStyle(
            color: Color(0xFF3B1F47),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),

          /// Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tabButton(
                    label: "Right",
                    value: "right",
                    color: const Color(0xFF34A853),
                    icon: Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _tabButton(
                    label: "Wrong",
                    value: "wrong",
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// Recording list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('voice-record')
                  .doc(widget.folderId)
                  .collection('records')
                  .where('type', isEqualTo: selectedTab)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6D00)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Failed to load recordings.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final docs = (snapshot.data?.docs ?? []).toList()
                  ..sort((a, b) {
                    final aDate = _parseDate(a.data()['created_at']);
                    final bDate = _parseDate(b.data()['created_at']);
                    return bDate.compareTo(aDate);
                  });

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "තවම පටිගත කිරීම් නැත",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final recording = Recording(
                      id: doc.id,
                      name: (data['name'] ?? 'Recording').toString(),
                      audioBase64: (data['audio_base64'] ?? '').toString(),
                      type: (data['type'] ?? '').toString(),
                      dateAdded: _parseDate(data['created_at']),
                    );
                    return _recordingCard(context, recording);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading
            ? null
            : () => _pickAudioFile(selectedTab == 'right'),
        backgroundColor: const Color(0xFFFF6D00),
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Upload Audio",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = selectedTab == value;

    return InkWell(
      onTap: () => setState(() => selectedTab = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordingCard(BuildContext context, Recording recording) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFF3E8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.audiotrack, color: Color(0xFFFF6D00)),
        ),
        title: Text(
          recording.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF3B1F47),
          ),
        ),
        subtitle: Text(
          "${recording.dateAdded.day}/${recording.dateAdded.month}/${recording.dateAdded.year}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(
            _playingRecordingId == recording.id
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            color: const Color(0xFFFF6D00),
          ),
          onPressed: () => _playRecording(recording),
        ),
      ),
    );
  }
}
