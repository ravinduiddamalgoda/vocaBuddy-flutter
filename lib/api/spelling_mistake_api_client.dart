import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SpellingMistakeApiClient {
  static const String _url =
      'https://spellingmistake-353748037778.asia-south1.run.app';

  Future<Map<String, dynamic>> checkSpellingMistake({
    required String audioFilePath,
    required String text,
  }) async {
    final trimmedPath = audioFilePath.trim();
    final trimmedText = text.trim();

    if (trimmedPath.isEmpty) {
      throw Exception('Audio file path is empty');
    }
    if (trimmedText.isEmpty) {
      throw Exception('Text is empty');
    }

    try {
      final audioFile = File(trimmedPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: $trimmedPath');
      }
      final fileLength = await audioFile.length();
      if (fileLength <= 0) {
        throw Exception('Audio file is empty: $trimmedPath');
      }
      final fileName = audioFile.uri.pathSegments.isNotEmpty
          ? audioFile.uri.pathSegments.last
          : 'recording.wav';
      final headerBytes = await audioFile.openRead(0, 16).first;
      final headerHex = headerBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');

      developer.log(
        '[API REQUEST][spellingMistake] url=$_url fields={text:$trimmedText} filePath=$trimmedPath fileName=$fileName bytes=$fileLength header=$headerHex',
        name: 'SpellingMistakeApiClient',
      );

      final request = http.MultipartRequest('POST', Uri.parse(_url))
        // ..headers['Accept'] = 'application/json'
        ..fields['text'] = trimmedText
        ..files.add(
          await http.MultipartFile.fromPath(
            'audio',
            trimmedPath,
            filename: fileName,
            contentType: MediaType('audio', 'wav'),
          ),
        );

      final streamed = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamed);

      developer.log(
        '[API RESPONSE][spellingMistake] status=${response.statusCode} body=${response.body}',
        name: 'SpellingMistakeApiClient',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Spelling mistake API failed ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      return decoded;
    } on TimeoutException {
      throw Exception('Spelling mistake request timed out');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response: $e');
    } catch (e) {
      rethrow;
    }
  }
}
