import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pronunciation_provider.dart';

class PronunciationScorePage extends StatefulWidget {
  final String classId;
  final int pronunciationIndex;

  const PronunciationScorePage({
    super.key,
    required this.classId,
    required this.pronunciationIndex,
  });

  @override
  PronunciationScorePageState createState() => PronunciationScorePageState();
}

class PronunciationScorePageState extends State<PronunciationScorePage> {
  late Future<Map<String, int>> _scoreFuture;

  @override
  void initState() {
    super.initState();
    _scoreFuture = _fetchScoreData();
  }

  Future<Map<String, int>> _fetchScoreData() async {
    final pronunciationProvider =
        Provider.of<PronunciationProvider>(context, listen: false);
    final score = await pronunciationProvider.getStudentScore(
        widget.classId, widget.pronunciationIndex);

    return {
      'score': score,
      'totalQuestions': 5,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Score'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<Map<String, int>>(
          future: _scoreFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            } else {
              final data = snapshot.data!;
              final score = data['score'] ?? 0;
              final totalQuestions = data['totalQuestions'] ?? 0;
              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.9, // 90% of screen width
                  height: 300, // Set a specific height for the card
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 10,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: score == 0
                        ? const Center(
                            child: Text(
                              'Evaluation Pending',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Your Score',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$score / $totalQuestions',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Percentage: ${((score / totalQuestions) * 100).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
