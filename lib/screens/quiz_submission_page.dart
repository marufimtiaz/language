import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';

class QuizSubmissionPage extends StatefulWidget {
  final String quizId;
  final String studentId;

  const QuizSubmissionPage({
    super.key,
    required this.quizId,
    required this.studentId,
  });

  @override
  QuizSubmissionPageState createState() => QuizSubmissionPageState();
}

class QuizSubmissionPageState extends State<QuizSubmissionPage> {
  List<int?> selectedAnswers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    setState(() {
      isLoading = true;
    });

    await Provider.of<QuizProvider>(context, listen: false)
        .fetchQuizDetails(widget.quizId);

    final quizData =
        Provider.of<QuizProvider>(context, listen: false).currentQuizDetails;
    if (quizData != null && quizData['questions'] != null) {
      setState(() {
        selectedAnswers = List.filled(quizData['questions'].length, null);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
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

    await Provider.of<QuizProvider>(context, listen: false)
        .submitQuiz(widget.quizId, widget.studentId, answers);

    Navigator.of(context).pop(); // Return to previous page after submission
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final quizData = quizProvider.currentQuizDetails;

        if (isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (quizData == null ||
            quizData['questions'] == null ||
            (quizData['questions'] as List).isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: const Center(
                child: Text('No questions available for this quiz.')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(quizData['title'] ?? 'Quiz')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ...(quizData['questions'] as List<dynamic>)
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
                            onChanged: (int? value) =>
                                _selectAnswer(index, value!),
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
      },
    );
  }
}
