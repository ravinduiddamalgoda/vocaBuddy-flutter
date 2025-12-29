import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
  final String name;
  final String path;
  final DateTime dateAdded;

  Recording({
    required this.name,
    required this.path,
    required this.dateAdded,
  });
}

class Folder {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<Recording> correctRecordings;
  final List<Recording> incorrectRecordings;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  })  : correctRecordings = [],
        incorrectRecordings = [];
}

/// =======================
/// HOME PAGE STATE
/// =======================
class _UploadVoiceRecordingsScreenState
    extends State<UploadVoiceRecordingsScreen> {
  final List<Folder> folders = [];

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'නව ෆෝල්ඩරයක් සාදන්න',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            onChanged: (value) => folderName = value,
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
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  setState(() {
                    folders.add(
                      Folder(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: folderName.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('සාදන්න'),
            ),
          ],
        );
      },
    );
  }

  void _openFolder(Folder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderDetailPage(
          folder: folder,
          onUpdate: () => setState(() {}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(
                      Icons.mic,
                      size: 40,
                      color: Colors.white,
                    ),
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
                  )
                ],
              ),
            ),

            /// FOLDERS LIST
            Expanded(
              child: folders.isEmpty
                  ? Center(
                child: Text(
                  "No folders yet. Create your first folder!",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return _buildFolderCard(folder);
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
        label: const Text(
          'නව ෆෝල්ඩරය',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    final total =
        folder.correctRecordings.length + folder.incorrectRecordings.length;

    return GestureDetector(
      onTap: () => _openFolder(folder),
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
                    "$total recordings",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Color(0xFFFF6D00)),
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
  final Folder folder;
  final VoidCallback onUpdate;

  const FolderDetailPage({
    super.key,
    required this.folder,
    required this.onUpdate,
  });

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  String selectedTab = 'correct';

  Future<void> _pickAudioFile(bool isCorrect) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          final recording = Recording(
            name: file.name,
            path: file.path ?? '',
            dateAdded: DateTime.now(),
          );

          if (isCorrect) {
            widget.folder.correctRecordings.add(recording);
          } else {
            widget.folder.incorrectRecordings.add(recording);
          }
        }
      });

      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordings = selectedTab == 'correct'
        ? widget.folder.correctRecordings
        : widget.folder.incorrectRecordings;

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
          widget.folder.name,
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
                    label: "නිවැරදි",
                    value: "correct",
                    color: const Color(0xFF34A853),
                    icon: Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _tabButton(
                    label: "වැරදි",
                    value: "incorrect",
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
            child: recordings.isEmpty
                ? Center(
              child: Text(
                "තවම පටිගත කිරීම් නැත",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return _recordingCard(context, recording);
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAudioFile(selectedTab == 'correct'),
        backgroundColor: const Color(0xFFFF6D00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "පටිගත කිරීම එක් කරන්න",
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
            )
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_fill, color: Color(0xFFFF6D00)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio playback feature')),
            );
          },
        ),
      ),
    );
  }
}
