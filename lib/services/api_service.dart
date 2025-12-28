import 'dart:convert';
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
}

