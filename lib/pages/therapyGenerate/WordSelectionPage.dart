import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'ActivityReviewPage.dart';

class WordSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedChildren;
  final String activityType;
  final String prompt;

  // from preview endpoint
  final Map<String, dynamic> preview;

  // request params needed for suggestions
  final String childId;
  final String letter;
  final String mode;
  final int level;
  final int count;

  const WordSelectionPage({
    super.key,
    required this.selectedChildren,
    required this.activityType,
    required this.prompt,
    required this.preview,
    required this.childId,
    required this.letter,
    required this.mode,
    required this.level,
    required this.count,
  });

  @override
  State<WordSelectionPage> createState() => _WordSelectionPageState();
}

class _WordSelectionPageState extends State<WordSelectionPage> {
  final ApiClient api = ApiClient();

  bool loading = true;
  String? error;

  // Combined list shown to therapist (DB + LLM)
  // Each item: { "text": "...", "source": "DB"|"LLM", "valid": true/false }
  List<Map<String, dynamic>> candidates = [];

  // Therapist selections
  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 1) DB words from preview
      final dbItems = (widget.preview["items"] as List? ?? []);
      final dbWords = dbItems
          .map((e) => e["text"].toString())
          .toSet()
          .toList();

      final combined = <Map<String, dynamic>>[
        for (final w in dbWords) {"text": w, "source": "DB", "valid": true},
      ];

      // 2) LLM suggestions if can_generate
      final canGenerate = widget.preview["can_generate"] == true;
      final missing = (widget.preview["missing_count"] ?? 0) as int;

      if (canGenerate && missing > 0) {
        final sug = await api.generateSuggestions(
          therapistPin: "1234", // demo pin (later from UI)
          childId: widget.childId,
          letter: widget.letter,
          mode: widget.mode,
          level: widget.level,
          missingCount: missing,
        );

        final list = (sug["candidates"] as List? ?? []);
        final seen = <String>{...dbWords}; // start with DB words so LLM can’t repeat them
        for (final c in list) {
          final word = c["word"].toString().trim();
          final isValid = c["valid"] == true;

          // only show valid words
          if (!isValid) continue;

          // remove duplicates (LLM repeats a lot)
          if (seen.contains(word)) continue;
          seen.add(word);

          combined.add({
            "text": word,
            "source": "LLM",
            "valid": true,
          });
        }
      }

      setState(() {
        candidates = combined;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _toggleSelect(String word) {
    setState(() {
      if (selected.contains(word)) {
        selected.remove(word);
      } else {
        selected.add(word);
      }
    });
  }

  Future<void> _continueToReview() async {
    if (selected.isEmpty) return;

    try {
      setState(() {
        loading = true;
        error = null;
      });

      // 1) Save therapist-approved words into DB
      final approveResp = await api.approveWords(
        therapistPin: "1234", // demo pin
        childId: widget.childId,
        letter: widget.letter,
        mode: widget.mode,
        level: widget.level,
        selectedWords: selected.toList(),
      );

      // 2) Use updated_preview from backend (best source of truth)
      final updatedPreview = (approveResp["updated_preview"] as Map<String, dynamic>?);

      if (updatedPreview == null) {
        throw Exception("Approve response missing updated_preview");
      }

      // 3) Navigate to Review using updated preview (now includes inserted words)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityReviewPage(
            selectedChildren: widget.selectedChildren,
            activityType: widget.activityType,
            prompt: widget.prompt,
            apiPreview: updatedPreview,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Words",
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)))
          : (error != null)
          ? Center(child: Text("Error: $error"))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pick words for practice (DB + LLM suggestions)",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final c = candidates[index];
                  final word = c["text"].toString();
                  final source = c["source"].toString();
                  final valid = c["valid"] == true;
                  final isSelected = selected.contains(word);

                  return Opacity(
                    opacity: valid ? 1.0 : 0.45,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        onTap: valid ? () => _toggleSelect(word) : null,
                        title: Text(word, style: const TextStyle(fontSize: 18)),
                        subtitle: Text(source == "DB" ? "Source: DB" : "Source: LLM"),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: selected.isEmpty ? null : _continueToReview,
                child: Text("Continue (${selected.length} selected)"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
