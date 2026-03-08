import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class VoicePredictApiClient {
  static const String _url =
      'https://voicepredict-353748037778.asia-south1.run.app';

  Future<Map<String, dynamic>> predictVoice({
    required String audioFilePath,
    required String targetWord,
  }) async {
    final word = targetWord.trim();
    if (audioFilePath.trim().isEmpty) {
      throw Exception('Audio file path is empty');
    }
    if (word.isEmpty) {
      throw Exception('Target word is empty');
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_url))
        ..fields['target_word'] = word
        ..files.add(
          await http.MultipartFile.fromPath(
            'audio_file',
            audioFilePath,
            filename: 'recording.wav',
            contentType: MediaType('audio', 'wav'),
          ),
        );

      final streamed = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamed);
      developer.log(
        '[API RESPONSE][voicePredict] status=${response.statusCode} body=${response.body}',
        name: 'VoicePredictApiClient',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Voice predict failed ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      return decoded;
    } on TimeoutException {
      throw Exception('Voice predict request timed out');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response: $e');
    } catch (e) {
      rethrow;
    }
  }
}
