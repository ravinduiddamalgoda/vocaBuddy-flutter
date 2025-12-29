import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class VoiceRecordingApp extends StatelessWidget {
  const VoiceRecordingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Input new Word to The System',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFF5E6),
      ),
      home: const HomePage(),
    );
  }
}

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
  final List<Recording> correctRecordings;
  final List<Recording> incorrectRecordings;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  })  : correctRecordings = [],
        incorrectRecordings = [];
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Folder> folders = [];

  @override

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('නව ෆෝල්ඩරයක් සාදන්න'),
          content: TextField(
            onChanged: (value) {
              folderName = value;
            },
            decoration: InputDecoration(
              hintText: 'ෆෝල්ඩර නම ඇතුළත් කරන්න',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.orange.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('අවලංගු කරන්න'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (folderName.isNotEmpty) {
                  setState(() {
                    folders.add(Folder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: folderName,
                      createdAt: DateTime.now(),
                    ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'අලුත් වචන එකතු කරන්න !',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'සිංහල Interactive Learning Platform',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Folders List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return _buildFolderCard(folder, index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewFolder,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('නව ෆෝල්ඩරය'),
      ),
    );
  }

  Widget _buildFolderCard(Folder folder, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Folder Header
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FolderDetailPage(
                    folder: folder,
                    onUpdate: () => setState(() {}),
                  ),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade50,
                    Colors.orange.shade100,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${folder.correctRecordings.length + folder.incorrectRecordings.length} recordings',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.orange),
                ],
              ),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'නිවැරදි',
                    folder.correctRecordings.length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'වැරදි',
                    folder.incorrectRecordings.length.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FolderDetailPage extends StatefulWidget {
  final Folder folder;
  final VoidCallback onUpdate;

  const FolderDetailPage({
    Key? key,
    required this.folder,
    required this.onUpdate,
  }) : super(key: key);

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
      backgroundColor: const Color(0xFFFFF5E6),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: Text(widget.folder.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'නිවැරදි පටිගත කිරීම්',
                    'correct',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'වැරදි පටිගත කිරීම්',
                    'incorrect',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Recordings List
          Expanded(
            child: recordings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'තවම පටිගත කිරීම් නැත',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return _buildRecordingCard(recording, index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAudioFile(selectedTab == 'correct'),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('පටිගත කිරීම එක් කරන්න'),
      ),
    );
  }

  Widget _buildTabButton(String label, String value, IconData icon, Color color) {
    final isSelected = selectedTab == value;
    return InkWell(
      onTap: () => setState(() => selectedTab = value),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard(Recording recording, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.audiotrack,
            color: Colors.orange,
          ),
        ),
        title: Text(
          recording.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${recording.dateAdded.day}/${recording.dateAdded.month}/${recording.dateAdded.year}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_filled, color: Colors.orange),
          onPressed: () {
            // Play audio functionality would go here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio playback feature')),
            );
          },
        ),
      ),
    );
  }
}