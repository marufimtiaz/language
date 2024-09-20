import 'package:flutter/material.dart';
import '../services/quiz_service.dart';

class QuizSubmissionPage extends StatefulWidget {
  final String quizId;
  final String studentId;

  const QuizSubmissionPage({
    Key? key,
    required this.quizId,
    required this.studentId,
  }) : super(key: key);

  @override
  QuizSubmissionPageState createState() => QuizSubmissionPageState();
}

class QuizSubmissionPageState extends State<QuizSubmissionPage> {
  final QuizService _quizService = QuizService();
  Map<String, dynamic>? quizData;
  List<int?> selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    final data = await _quizService.getQuizDetails(widget.quizId);
    setState(() {
      quizData = data;
      if (data != null && data['questions'] != null) {
        selectedAnswers = List.filled(data['questions'].length, null);
      }
    });
  }

  void _selectAnswer(int questionIndex, int answerIndex) {
    setState(() {
      selectedAnswers[questionIndex] = answerIndex;
    });
  }

  Future<void> _submitQuiz() async {
    if (selectedAnswers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please answer all questions before submitting.')),
      );
      return;
    }

    List<Map<String, dynamic>> answers = [];
    for (int i = 0; i < selectedAnswers.length; i++) {
      answers.add({
        'questionIndex': i,
        'selectedAnswer': selectedAnswers[i],
      });
    }

    await _quizService.submitQuiz(widget.quizId, widget.studentId, answers);
    Navigator.of(context).pop(); // Return to previous page after submission
  }

  @override
  Widget build(BuildContext context) {
    if (quizData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(quizData!['title'] ?? 'Quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...(quizData!['questions'] as List<dynamic>)
              .asMap()
              .entries
              .map((entry) {
            int index = entry.key;
            Map<String, dynamic> question = entry.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}: ${question['question']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...(question['options'] as List<dynamic>)
                        .asMap()
                        .entries
                        .map((option) {
                      int optionIndex = option.key;
                      String optionText = option.value;
                      return RadioListTile<int>(
                        title: Text(optionText),
                        value: optionIndex,
                        groupValue: selectedAnswers[index],
                        onChanged: (int? value) => _selectAnswer(index, value!),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitQuiz,
            child: const Text('Submit Quiz'),
          ),
        ],
      ),
    );
  }
}
