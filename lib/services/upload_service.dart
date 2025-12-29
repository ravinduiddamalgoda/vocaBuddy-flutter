import 'dart:io';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Global upload service that manages uploads across the app
/// Allows uploads to continue even when navigating away
class UploadService extends ChangeNotifier {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  // Track active uploads
  final Map<String, UploadTask> _activeUploads = {};
  
  // Global scaffold messenger key for showing notifications
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Map<String, UploadTask> get activeUploads => Map.unmodifiable(_activeUploads);
  bool get hasActiveUploads => _activeUploads.isNotEmpty;

  /// Start uploading a file
  Future<void> uploadFile(File file, String fileName) async {
    final taskId = '${fileName}_${DateTime.now().millisecondsSinceEpoch}';
    final task = UploadTask(
      id: taskId,
      fileName: fileName,
      file: file,
      progress: 0.0,
      status: UploadStatus.uploading,
    );

    _activeUploads[taskId] = task;
    notifyListeners();

    try {
      // Upload phase: 0-70% progress
      task.status = UploadStatus.uploading;
      
      // Start processing simulation that runs in parallel
      int simulatedProgress = 70;
      bool processingComplete = false;
      
      final processingSimulation = (() async {
        // Wait a bit for upload to reach 70%
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Switch to processing status
        if (_activeUploads.containsKey(taskId)) {
          task.status = UploadStatus.processing;
          task.progress = 0.7;
          notifyListeners();
        }
        
        // Simulate processing progress (70% -> 95%)
        while (!processingComplete && simulatedProgress < 95 && _activeUploads.containsKey(taskId)) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (task.status == UploadStatus.processing && _activeUploads.containsKey(taskId)) {
            simulatedProgress += 3;
            if (simulatedProgress <= 95) {
              task.progress = simulatedProgress / 100.0;
              notifyListeners();
            }
          }
        }
      })();
      
      // Upload file (this blocks until backend processing is complete)
      await ApiService.uploadPdf(
        file,
        fileName,
        onProgress: (uploadProgress) {
          // Map upload progress to 0-70% of total
          if (task.status == UploadStatus.uploading) {
            task.progress = uploadProgress * 0.7;
            notifyListeners();
          }
        },
      );
      
      // API call complete - processing is done
      processingComplete = true;
      await processingSimulation; // Let simulation finish if needed
      
      // Set to 100% and mark as completed
      task.status = UploadStatus.completed;
      task.progress = 1.0;
      notifyListeners();

      // Show success notification only after processing is complete
      // Use a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 100));
      _showSuccessNotification(fileName);

      // Remove from active uploads after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _activeUploads.remove(taskId);
        notifyListeners();
      });
    } catch (e) {
      task.status = UploadStatus.failed;
      task.error = e.toString();
      notifyListeners();

      // Show error notification
      _showErrorNotification(fileName, e.toString());

      // Remove from active uploads after a delay
      Future.delayed(const Duration(seconds: 3), () {
        _activeUploads.remove(taskId);
        notifyListeners();
      });
    }
  }

  void _showSuccessNotification(String fileName) {
    // Use WidgetsBinding to ensure we're on the main thread and UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = scaffoldMessengerKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$fileName uploaded successfully!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        print('⚠️ Cannot show success notification: context is null');
        // Retry after a short delay if context is not ready
        Future.delayed(const Duration(milliseconds: 500), () {
          final retryContext = scaffoldMessengerKey.currentContext;
          if (retryContext != null) {
            ScaffoldMessenger.of(retryContext).showSnackBar(
              SnackBar(
                content: Text('$fileName uploaded successfully!'),
                backgroundColor: const Color(0xFF22C55E),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    });
  }

  void _showErrorNotification(String fileName, String error) {
    final context = scaffoldMessengerKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to upload $fileName',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Cancel an upload (if needed in future)
  void cancelUpload(String taskId) {
    _activeUploads.remove(taskId);
    notifyListeners();
  }
}

/// Represents an upload task
class UploadTask {
  final String id;
  final String fileName;
  final File file;
  double progress;
  UploadStatus status;
  String? error;

  UploadTask({
    required this.id,
    required this.fileName,
    required this.file,
    required this.progress,
    required this.status,
    this.error,
  });
}

enum UploadStatus {
  uploading,
  processing,
  completed,
  failed,
}

