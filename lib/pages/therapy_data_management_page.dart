import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/upload_service.dart';

class TherapyDataManagementPage extends StatefulWidget {
  const TherapyDataManagementPage({super.key});

  @override
  State<TherapyDataManagementPage> createState() => _TherapyDataManagementPageState();
}

class _TherapyDataManagementPageState extends State<TherapyDataManagementPage> {
  bool _isDragging = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _uploadedFiles = [];

  final UploadService _uploadService = UploadService();
  UploadTask? _currentUploadTask;

  // Delete progress tracking
  bool _isDeleting = false;
  double _deleteProgress = 0.0;
  String? _deletingFileName;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
    _uploadService.addListener(_onUploadUpdate);
    
    // Check for active uploads when page loads (in case user navigated away and came back)
    _checkActiveUploads();
  }
  
  void _checkActiveUploads() {
    final uploads = _uploadService.activeUploads.values.toList();
    if (uploads.isNotEmpty) {
      final activeTask = uploads.last;
      print('📤 Found active upload: ${activeTask.fileName} - ${(activeTask.progress * 100).toStringAsFixed(1)}% - ${activeTask.status}');
      setState(() {
        _currentUploadTask = activeTask;
      });
    } else {
      print('📤 No active uploads found');
      setState(() {
        _currentUploadTask = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check for active uploads when page becomes visible again
        _checkActiveUploads();
        
        if (_uploadedFiles.isEmpty && !_isLoading) {
          _loadPdfFiles();
        }
      }
    });
  }

  @override
  void dispose() {
    _uploadService.removeListener(_onUploadUpdate);
    super.dispose();
  }

  void _onUploadUpdate() {
    if (mounted) {
      final uploads = _uploadService.activeUploads.values.toList();
      if (uploads.isNotEmpty) {
        // Get the most recent/active upload task
        final activeTask = uploads.last;
        final previousStatus = _currentUploadTask?.status;
        
        setState(() {
          _currentUploadTask = activeTask;
        });

        // Only reload files when upload transitions from processing/completed to completed
        // Don't reload during active upload/processing
        if (activeTask.status == UploadStatus.completed && 
            previousStatus != UploadStatus.completed) {
          // Upload just completed - reload files after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _currentUploadTask?.status == UploadStatus.completed) {
              _loadPdfFiles();
            }
          });
        }
      } else {
        // No active uploads - only reload if we had an upload before
        final hadUpload = _currentUploadTask != null;
        setState(() {
          _currentUploadTask = null;
        });
        
        // Only reload if we just finished an upload (not on initial load)
        if (hadUpload) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _loadPdfFiles();
            }
          });
        }
      }
    }
  }

  bool get _isUploading => _currentUploadTask != null &&
      (_currentUploadTask!.status == UploadStatus.uploading ||
          _currentUploadTask!.status == UploadStatus.processing);

  double get _uploadProgress => _currentUploadTask?.progress ?? 0.0;

  Future<void> _loadPdfFiles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading PDF files from backend...');
      final files = await ApiService.listPdfFiles();
      print('Received ${files.length} files from API');

      if (mounted) {
        setState(() {
          _uploadedFiles = files.map((file) => {
            'name': file['name'],
            'size': file['size'],
          }).toList();
          _isLoading = false;
        });

        print('Loaded ${_uploadedFiles.length} PDF files from backend');
        print('Files: ${_uploadedFiles.map((f) => f['name']).join(', ')}');

        if (_uploadedFiles.isNotEmpty) {
          print('✅ Successfully loaded ${_uploadedFiles.length} PDF files');
        } else {
          print('⚠️ No PDF files found (list is empty)');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('❌ Error loading PDF files: $e');
        print('Error type: ${e.runtimeType}');
        print('Error details: ${e.toString()}');
        _showErrorSnackBar('Failed to load PDF files: ${e.toString()}');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Start uploads - don't reload list yet, wait for upload to complete
        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            final file = File(pickedFile.path!);
            _uploadService.uploadFile(file, pickedFile.name);
          }
        }
        // Don't reload here - let _onUploadUpdate handle it when upload completes
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to start upload: ${e.toString()}');
      }
    }
  }

  String _formatFileSize(dynamic bytes) {
    final size = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _removeFile(int index) async {
    final fileName = _uploadedFiles[index]['name'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete PDF?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this file?',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. The file will be permanently removed from the knowledge base.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _deleteProgress = 0.0;
      _deletingFileName = fileName;
    });

    try {
      for (int i = 0; i <= 70; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _deleteProgress = i / 100.0;
          });
        }
      }

      await ApiService.deletePdf(fileName);

      for (int i = 70; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _deleteProgress = i / 100.0;
          });
        }
      }

      await _loadPdfFiles();

      if (mounted) {
        setState(() {
          _isDeleting = false;
          _deleteProgress = 0.0;
          _deletingFileName = null;
        });

        _showSuccessSnackBar('$fileName deleted successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _deleteProgress = 0.0;
          _deletingFileName = null;
        });
        _showErrorSnackBar('Failed to delete PDF: ${e.toString()}');
      }
    }
  }

  Future<void> _clearAllFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete All Files?'),
        content: const Text(
          'Are you sure you want to delete all PDF files from the knowledge base? This cannot be undone.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int deletedCount = 0;
      for (var file in List<Map<String, dynamic>>.from(_uploadedFiles)) {
        try {
          await ApiService.deletePdf(file['name']);
          deletedCount++;
        } catch (e) {
          print('Failed to delete ${file['name']}: $e');
        }
      }

      await _loadPdfFiles();
      if (mounted) {
        if (deletedCount > 0) {
          _showSuccessSnackBar('$deletedCount file(s) deleted successfully!');
        }
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
                color: Colors.black.withValues(alpha: 0.08),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Therapy Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              'PDF Documents',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Upload therapy data PDFs. They will be automatically saved and added to the knowledge base for the chatbot.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E40AF),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: DragTarget<Object>(
                  onWillAcceptWithDetails: (details) {
                    if (!_isUploading) {
                      setState(() => _isDragging = true);
                      return true;
                    }
                    return false;
                  },
                  onLeave: (data) {
                    setState(() => _isDragging = false);
                  },
                  onAcceptWithDetails: (details) {
                    setState(() => _isDragging = false);
                    _pickFile();
                  },
                  builder: (context, candidateData, rejectedData) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? const Color(0xFFF0FDF4)
                            : _isUploading
                            ? const Color(0xFFFEF3C7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isDragging
                              ? const Color(0xFF22C55E)
                              : _isUploading
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _isDragging
                                  ? const Color(0xFFF0FDF4)
                                  : _isUploading
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isUploading
                                  ? Icons.upload_file
                                  : _isDragging
                                  ? Icons.cloud_download
                                  : Icons.cloud_upload_outlined,
                              size: 40,
                              color: _isUploading
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF22C55E),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            _isUploading
                                ? (_currentUploadTask?.status == UploadStatus.processing
                                ? 'Processing...'
                                : 'Uploading...')
                                : _isDragging
                                ? 'Drop files here'
                                : 'Upload Therapy Data',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _isDragging
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _isUploading
                                ? (_currentUploadTask?.status == UploadStatus.processing
                                ? 'Adding to knowledge base...'
                                : 'Uploading file to server...')
                                : _isDragging
                                ? 'Release to upload'
                                : 'Drag & drop PDF files or click to browse',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          if (_isUploading && _currentUploadTask != null) ...[
                            Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Stack(
                                    children: [
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _uploadProgress.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF22C55E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _currentUploadTask!.status == UploadStatus.processing
                                            ? 'Processing ${_currentUploadTask!.fileName}... ${(_uploadProgress * 100).toStringAsFixed(1)}%'
                                            : 'Uploading ${_currentUploadTask!.fileName}... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF22C55E),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You can navigate away - upload will continue in background',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'PDF only • Max 10MB per file',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              if (_isLoading) ...[
                const SizedBox(height: 32),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF22C55E),
                  ),
                ),
              ] else if (_uploadedFiles.isNotEmpty) ...[
                if (_isDeleting && _deletingFileName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Deleting $_deletingFileName...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF991B1B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_deleteProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _deleteProgress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'PDF Files (${_uploadedFiles.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: _isDeleting ? null : _loadPdfFiles,
                          tooltip: 'Refresh',
                        ),
                        TextButton.icon(
                          onPressed: _isDeleting ? null : _clearAllFiles,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          label: const Text(
                            'Delete All',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _uploadedFiles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Color(0xFFEF4444),
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(file['size']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          SizedBox(
                            width: 40,
                            height: 40,
                            child: _isDeleting && _deletingFileName == file['name']
                                ? Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: _deleteProgress,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            )
                                : IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Color(0xFFEF4444),
                              ),
                              onPressed: _isDeleting ? null : () => _removeFile(index),
                              tooltip: 'Delete',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              if (_uploadedFiles.isEmpty && !_isUploading && !_isLoading) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.folder_open,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No files uploaded yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload PDF files to get started',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}