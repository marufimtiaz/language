import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';

class QuizSubmissionPage extends StatefulWidget {
  final String classId;
  final int quizIndex;
  final String studentId;

  const QuizSubmissionPage({
    super.key,
    required this.classId,
    required this.quizIndex,
    required this.studentId,
  });

  @override
  QuizSubmissionPageState createState() => QuizSubmissionPageState();
}

class QuizSubmissionPageState extends State<QuizSubmissionPage> {
  Map<String, int> selectedAnswers = {};
  List<Icon> scoreKeeper = [];
  bool isLoading = true;
  int currentQuestionIndex = 0;
  List<Map<String, dynamic>>? quizData;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    setState(() {
      isLoading = true;
    });

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizData =
        await quizProvider.fetchQuizQuestions(widget.classId, widget.quizIndex);

    if (quizData != null) {
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    if (quizData == null) return;

    final currentQuestion = quizData![currentQuestionIndex];
    final correctAnswerIndex = currentQuestion['answer'];

    setState(() {
      selectedAnswers[currentQuestionIndex.toString()] = answerIndex;

      // Add feedback icon
      if (answerIndex == correctAnswerIndex) {
        scoreKeeper.add(const Icon(Icons.check, color: Colors.green));
      } else {
        scoreKeeper.add(const Icon(Icons.close, color: Colors.red));
      }

      // Move to next question or finish quiz
      if (currentQuestionIndex < quizData!.length - 1) {
        currentQuestionIndex++;
      } else {
        _submitQuiz();
      }
    });
  }

  Future<void> _submitQuiz() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    int correctAnswers =
        scoreKeeper.where((icon) => icon.color == Colors.green).length;
    bool result = await quizProvider.submitQuiz(
      widget.classId,
      widget.quizIndex,
      correctAnswers,
    );

    if (result) {
      _showResult();
    } else {
      // Handle submission failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit quiz. Please try again.')),
      );
    }
  }

  void _showResult() {
    int correctAnswers =
        scoreKeeper.where((icon) => icon.color == Colors.green).length;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quiz Completed'),
          content: Text(
              'You got $correctAnswers out of ${selectedAnswers.length} correct!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(); // Return to previous page after viewing results
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quizData == null || quizData!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body:
            const Center(child: Text('No questions available for this quiz.')),
      );
    }

    final currentQuestion = quizData![currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Question ${currentQuestionIndex + 1} of ${quizData!.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentQuestion['questionText'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...(currentQuestion['options'] as List<dynamic>)
                .asMap()
                .entries
                .map((option) {
              int optionIndex = option.key;
              String optionText = option.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () => _selectAnswer(optionIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    optionText,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              );
            }),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: scoreKeeper,
            ),
          ],
        ),
      ),
    );
  }
}
