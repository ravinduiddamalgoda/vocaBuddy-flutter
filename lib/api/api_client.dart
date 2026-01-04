import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Android Emulator -> host PC
  static const String baseUrl = "http://10.0.2.2:8000";

  Future<Map<String, dynamic>> previewActivity({
    required String childId,
    required String letter,
    required String mode,
    required int level,
    required int count,
  }) async {
    final url = Uri.parse("$baseUrl/activity/preview");

    final body = {
      "child_id": childId,
      "letter": letter,
      "mode": mode,
      "level": level,
      "count": count,
    };

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception("Preview failed ${resp.statusCode}: ${resp.body}");
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
  Future<Map<String, dynamic>> generateSuggestions({
    required String therapistPin,
    required String childId,
    required String letter,
    required String mode,
    required int level,
    required int missingCount,
  }) async {
    final url = Uri.parse("$baseUrl/activity/generate");

    final body = {
      "therapist_pin": therapistPin,
      "child_id": childId,
      "letter": letter,
      "mode": mode,
      "level": level,
      "missing_count": missingCount,
    };

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception("Generate suggestions failed ${resp.statusCode}: ${resp.body}");
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approveWords({
    required String therapistPin,
    required String childId,
    required String letter,
    required String mode,
    required int level,
    required List<String> selectedWords,
  }) async {
    final url = Uri.parse("$baseUrl/activity/approve");

    final body = {
      "therapist_pin": therapistPin,
      "child_id": childId,
      "letter": letter,
      "mode": mode,
      "level": level,
      "requested_count": selectedWords.length, // ✅ required by backend
      "approved_words": selectedWords,
    };

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception("Approve failed ${resp.statusCode}: ${resp.body}");
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }


}
