import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vocabuddy/api/activity_generate_api_client.dart';
import 'package:vocabuddy/pages/therapyGenerate/ActivityReviewPage.dart';

class SelectChildrenPage extends StatefulWidget {
  const SelectChildrenPage({Key? key}) : super(key: key);

  @override
  State<SelectChildrenPage> createState() => _SelectChildrenPageState();
}

class _SelectChildrenPageState extends State<SelectChildrenPage> {
  final TextEditingController _promptController = TextEditingController();
  final ActivityGenerateApiClient _activityApi = ActivityGenerateApiClient();

  final List<Map<String, dynamic>> _children = [];
  bool _isChildrenLoading = true;
  String? _childrenLoadError;
  String _searchQuery = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isChildrenLoading = true;
      _childrenLoadError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'role',
            whereIn: ['children', 'childran', 'child', 'Children', 'Childran'],
          )
          .get();

      final children =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': _parseName(data['name'], doc.id),
              'age': _parseAge(data['age']),
              'selected': false,
            };
          }).toList()..sort(
            (a, b) => (a['name'] as String).toLowerCase().compareTo(
              (b['name'] as String).toLowerCase(),
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _children
          ..clear()
          ..addAll(children);
        _isChildrenLoading = false;
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '[FIREBASE ERROR][loadChildren] code=${e.code} message=${e.message}',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _isChildrenLoading = false;
        _childrenLoadError =
            'Failed to load children [${e.code}]: ${e.message ?? e.toString()}';
      });
    } catch (e) {
      debugPrint('[ERROR][loadChildren] $e');
      if (!mounted) {
        return;
      }

      setState(() {
        _isChildrenLoading = false;
        _childrenLoadError = 'Failed to load children: $e';
      });
    }
  }

  String _parseName(dynamic rawName, String fallbackId) {
    final value = rawName?.toString().trim() ?? '';
    return value.isEmpty ? fallbackId : value;
  }

  int _parseAge(dynamic rawAge) {
    if (rawAge is int) {
      return rawAge;
    }
    if (rawAge is num) {
      return rawAge.toInt();
    }
    if (rawAge is String) {
      return int.tryParse(rawAge.trim()) ?? 0;
    }
    return 0;
  }

  Future<void> _generateActivityForSelectedChild() async {
    if (_isGenerating) {
      return;
    }

    final selectedChild = _children.firstWhere(
      (child) => child['selected'] == true,
      orElse: () => <String, dynamic>{},
    );

    if (selectedChild.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child first.')),
      );
      return;
    }

    final childId = selectedChild['id'].toString();
    final letter = _promptController.text.trim();

    if (letter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter activity text.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await _activityApi.generateEasyActivity(letter: letter);
      final dataList = (response['data'] is List)
          ? response['data'] as List
          : <dynamic>[];
      String? createdSessionId;

      try {
        final sessionsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(childId)
            .collection('sessions');
        final sessionDoc = sessionsRef.doc();
        createdSessionId = sessionDoc.id;

        final batch = FirebaseFirestore.instance.batch();
        batch.set(sessionDoc, {
          'request': {'letter': letter, 'level': 'easy'},
          'status': response['status'] ?? 'success',
          'total_found': response['total_found'] ?? dataList.length,
          'objects_count': dataList.length,
          'created_at': FieldValue.serverTimestamp(),
        });

        for (var index = 0; index < dataList.length; index++) {
          final item = dataList[index];
          if (item is! Map) {
            continue;
          }
          final object = Map<String, dynamic>.from(item);
          object['index'] = index;
          object['created_at'] = FieldValue.serverTimestamp();

          batch.set(sessionDoc.collection('objects').doc(), object);
        }

        await batch.commit();
      } on FirebaseException catch (e) {
        debugPrint(
          '[FIREBASE ERROR][saveSession] code=${e.code} message=${e.message}',
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firebase error [${e.code}]: ${e.message ?? e.toString()}',
            ),
          ),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      if (createdSessionId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session was saved but session ID is missing.'),
          ),
        );
        return;
      }

      final previewItems = dataList
          .whereType<Map>()
          .map((item) => {'text': (item['word'] ?? '').toString()})
          .where((item) => item['text']!.isNotEmpty)
          .toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityReviewPage(
            selectedChildren: [
              {
                'id': selectedChild['id'],
                'name': selectedChild['name'],
                'age': selectedChild['age'],
              },
            ],
            activityType: 'Generate Activity',
            prompt: letter,
            apiPreview: {
              'items': previewItems,
              'target_letter': letter,
              'returned_count': dataList.length,
            },
            firebaseChildId: childId,
            firebaseSessionId: createdSessionId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[API ERROR][generateActivity] $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('API error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedChild = _children.any(
      (child) => child['selected'] == true,
    );
    final hasPrompt = _promptController.text.trim().isNotEmpty;

    final filteredChildren = _children.where((child) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      return child['name'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Activity',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an activity here',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Child',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Search and choose one child',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search child...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 240,
                      child: _isChildrenLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _childrenLoadError != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _childrenLoadError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: _loadChildren,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredChildren.isEmpty
                          ? const Center(
                              child: Text(
                                'No children found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredChildren.length,
                              itemBuilder: (context, index) {
                                final child = filteredChildren[index];
                                final isSelected = child['selected'] == true;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        for (final c in _children) {
                                          c['selected'] = false;
                                        }
                                        child['selected'] = true;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFFF4E6)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFF9800)
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                child['name'][0]
                                                    .toString()
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  child['name'].toString(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Age: ${child['age']}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: isSelected
                                                ? const Color(0xFFFF9800)
                                                : const Color(0xFFCBD5E1),
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF64748B),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Activity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Type letter/word to generate easy activity',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _promptController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g., ත  or  water',
                          hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Builder(
                builder: (context) {
                  final canGenerate =
                      hasSelectedChild && hasPrompt && !_isGenerating;
                  final hasRequiredInput = hasSelectedChild && hasPrompt;

                  return Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: canGenerate
                          ? const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: canGenerate ? null : const Color(0xFFE2E8F0),
                      boxShadow: canGenerate
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canGenerate
                            ? _generateActivityForSelectedChild
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isGenerating)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              if (_isGenerating) const SizedBox(width: 10),
                              Text(
                                _isGenerating
                                    ? 'Generating Activity...'
                                    : 'Generate Activity',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: canGenerate
                                      ? Colors.white
                                      : (hasRequiredInput
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (canGenerate && !_isGenerating)
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
