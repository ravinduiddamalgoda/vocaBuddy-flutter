import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';

/// API Service for communicating with the backend
/// Uses 10.0.2.2 for Android emulator (maps to host machine's localhost)
/// Uses localhost for other platforms
class ApiService {
  // Base URL configuration
  // 10.0.2.2 is the special IP address that Android emulator uses to access host machine's localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost
      return 'http://localhost:8000';
    } else {
      // For web, desktop, etc.
      return 'http://localhost:8000';
    }
  }

  /// Ask a question to the AI assistant
  /// Returns the AI-generated answer
  static Future<String> askQuestion(String question) async {
    try {
      final url = Uri.parse('$baseUrl/parentdashboard/ask');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check if the backend is running.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'No answer received from the server.';
      } else {
        throw Exception('Failed to get answer: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'Cannot connect to backend server.\n\n'
                'Please make sure:\n'
                '1. Backend is running on your PC (python main.py)\n'
                '2. Backend is accessible at http://localhost:8000\n'
                '3. For Android emulator, backend should be running on host machine\n\n'
                'Error: ${e.toString()}'
        );
      }
      rethrow;
    }
  }

  /// Check if the backend is healthy and accessible
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/parentdashboard/health');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return http.Response('Timeout', 408);
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// List all PDF files
  /// Returns a list of PDF file information
  static Future<List<Map<String, dynamic>>> listPdfFiles() async {
    try {
      final url = Uri.parse('$baseUrl/parentdashboard/pdfs');
      print('📡 Requesting PDF list from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Request timeout');
          throw Exception('Request timeout. Please check if the backend is running.');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Parsed data type: ${data.runtimeType}');
        print('📦 Data keys: ${data.keys}');
        
        if (data['files'] is List) {
          final files = List<Map<String, dynamic>>.from(data['files']);
          print('✅ Found ${files.length} PDF files in response');
          return files;
        }
        print('⚠️ No files array in response, returning empty list');
        return [];
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to list PDFs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in listPdfFiles: $e');
      print('❌ Exception type: ${e.runtimeType}');
      
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception(
            'Cannot connect to backend server.\n\n'
                'Please make sure:\n'
                '1. Backend is running on your PC (python main.py)\n'
                '2. Backend is accessible at $baseUrl\n'
                '3. For Android emulator, backend should be running on host machine\n\n'
                'Error: ${e.toString()}'
        );
      }
      rethrow;
    }
  }

  /// Upload a PDF file with progress tracking
  /// file: The PDF file to upload
  /// fileName: The name of the file
  /// onProgress: Callback function that receives progress (0.0 to 1.0)
  static Future<void> uploadPdf(
    File file,
    String fileName, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/parentdashboard/pdfs/upload');

      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      // Get file size for progress calculation
      final fileSize = await file.length();
      final totalLength = request.contentLength ?? fileSize;
      
      // Start progress at 5%
      if (onProgress != null) {
        onProgress(0.05);
      }

      // Send request and track progress
      final streamedRequest = await request.send();
      
      // Track bytes received (which approximates upload progress)
      int bytesReceived = 0;
      final List<int> responseBytes = [];
      
      // Create a completer to wait for stream to complete
      final completer = Completer<void>();
      
      // Listen to response stream and track progress
      streamedRequest.stream.timeout(
        const Duration(seconds: 120),
        onTimeout: (EventSink<List<int>> sink) {
          sink.close();
          throw Exception('Upload timeout. Please check if the backend is running.');
        },
      ).listen(
        (List<int> chunk) {
          bytesReceived += chunk.length;
          responseBytes.addAll(chunk);
          // Estimate progress: 10-90% based on response size
          // (This is approximate since we can't easily track request bytes)
          if (onProgress != null && totalLength > 0) {
            final estimatedProgress = 0.1 + (bytesReceived / totalLength * 0.8).clamp(0.0, 0.8);
            onProgress(estimatedProgress);
          }
        },
        onDone: () {
          // Show 100% when complete
          if (onProgress != null) {
            onProgress(1.0);
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        cancelOnError: true,
      );

      // Wait for stream to complete
      await completer.future;

      // Create response from collected bytes
      final response = http.Response(
        utf8.decode(responseBytes, allowMalformed: true),
        streamedRequest.statusCode,
        headers: streamedRequest.headers,
        request: streamedRequest.request,
        isRedirect: streamedRequest.isRedirect,
        persistentConnection: streamedRequest.persistentConnection,
        reasonPhrase: streamedRequest.reasonPhrase,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upload PDF: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'Cannot connect to backend server.\n\n'
                'Please make sure:\n'
                '1. Backend is running on your PC (python main.py)\n'
                '2. Backend is accessible at http://localhost:8000\n'
                '3. For Android emulator, backend should be running on host machine\n\n'
                'Error: ${e.toString()}'
        );
      }
      rethrow;
    }
  }

  /// Update/rename a PDF file
  /// oldFileName: The current name of the PDF file
  /// newFileName: The new name for the PDF file (without .pdf extension)
  static Future<void> updatePdfName(String oldFileName, String newFileName) async {
    try {
      final url = Uri.parse('$baseUrl/parentdashboard/pdfs/update');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_name': oldFileName,
          'new_name': newFileName.endsWith('.pdf') 
              ? newFileName 
              : '$newFileName.pdf',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check if the backend is running.');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update PDF: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'Cannot connect to backend server.\n\n'
                'Please make sure:\n'
                '1. Backend is running on your PC (python main.py)\n'
                '2. Backend is accessible at http://localhost:8000\n'
                '3. For Android emulator, backend should be running on host machine\n\n'
                'Error: ${e.toString()}'
        );
      }
      rethrow;
    }
  }

  /// Delete a PDF file
  /// fileName: The name of the PDF file to delete
  static Future<void> deletePdf(String fileName) async {
    try {
      final url = Uri.parse('$baseUrl/parentdashboard/pdfs/delete?file_name=${Uri.encodeComponent(fileName)}');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check if the backend is running.');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete PDF: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'Cannot connect to backend server.\n\n'
                'Please make sure:\n'
                '1. Backend is running on your PC (python main.py)\n'
                '2. Backend is accessible at http://localhost:8000\n'
                '3. For Android emulator, backend should be running on host machine\n\n'
                'Error: ${e.toString()}'
        );
      }
      rethrow;
    }
  }
}

