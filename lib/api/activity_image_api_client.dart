import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ActivityImageApiClient {
  static const String imageUrl =
      'https://image-353748037778.asia-south1.run.app';

  Future<List<String>> fetchImagesForWord({required String word}) async {
    final normalizedWord = word.trim();
    if (normalizedWord.isEmpty) {
      throw Exception('Word is required for image generation');
    }

    final body = {'word': normalizedWord};
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(imageUrl),
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint(
        '[API ERROR][image] Request failed url=$imageUrl headers=$headers body=$body error=$e',
      );
      throw Exception('Image request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[API ERROR][image] url=$imageUrl status=${response.statusCode} responseHeaders=${response.headers} response=${response.body}',
      );
      throw Exception(
        'Image API failed ${response.statusCode}: ${response.body}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      debugPrint(
        '[API ERROR][image] Invalid JSON url=$imageUrl response=${response.body} parseError=$e',
      );
      throw Exception('Image API returned invalid JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      debugPrint(
        '[API ERROR][image] Unexpected response type=${decoded.runtimeType} body=${response.body}',
      );
      throw Exception('Unexpected image response format');
    }

    final images = (decoded['images'] as List? ?? <dynamic>[])
        .map((item) => item.toString().trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return images;
  }
}
