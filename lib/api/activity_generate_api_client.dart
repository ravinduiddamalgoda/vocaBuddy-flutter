import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ActivityGenerateApiClient {
  static const String generateUrl =
      'https://voice-353748037778.europe-west1.run.app';

  Future<Map<String, dynamic>> generateEasyActivity({
    required String letter,
  }) async {
    final normalizedLetter = letter.trim();
    if (normalizedLetter.isEmpty) {
      throw Exception('Letter is required');
    }

    final body = {'letter': normalizedLetter, 'level': 'easy'};
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final encodedBody = jsonEncode(body);

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(generateUrl),
        headers: headers,
        body: encodedBody,
      );
    } catch (e) {
      debugPrint(
        '[API ERROR] Request failed url=$generateUrl headers=$headers body=$body error=$e',
      );
      throw Exception('Generate activity request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[API ERROR] url=$generateUrl status=${response.statusCode} responseHeaders=${response.headers} response=${response.body}',
      );
      throw Exception(
        'Generate activity failed ${response.statusCode}: ${response.body}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      debugPrint(
        '[API ERROR] Invalid JSON url=$generateUrl response=${response.body} parseError=$e',
      );
      throw Exception('Generate activity returned invalid JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      debugPrint(
        '[API ERROR] Unexpected response type ${decoded.runtimeType} body=${response.body}',
      );
      throw Exception('Unexpected response format from generate API');
    }

    return decoded;
  }
}
