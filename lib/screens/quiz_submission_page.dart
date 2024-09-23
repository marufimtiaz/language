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
  List<Icon> scoreKeeper = [];
  bool isLoading = true;
  int currentQuestionIndex = 0;

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

  void _selectAnswer(int answerIndex) {
    final quizData =
        Provider.of<QuizProvider>(context, listen: false).currentQuizDetails;
    final questions = quizData!['questions'] as List<dynamic>;
    final currentQuestion = questions[currentQuestionIndex];
    final correctAnswerIndex = currentQuestion['correctAnswer'];

    setState(() {
      selectedAnswers[currentQuestionIndex] = answerIndex;

      // Add feedback icon
      if (answerIndex == correctAnswerIndex) {
        scoreKeeper.add(Icon(Icons.check, color: Colors.green));
      } else {
        scoreKeeper.add(Icon(Icons.close, color: Colors.red));
      }

      // Move to next question or finish quiz
      if (currentQuestionIndex < selectedAnswers.length - 1) {
        currentQuestionIndex++;
      } else {
        _submitQuiz();
      }
    });
  }

  Future<void> _submitQuiz() async {
    List<Map<String, dynamic>> answers = [];
    for (int i = 0; i < selectedAnswers.length; i++) {
      answers.add({
        'questionIndex': i,
        'selectedAnswer': selectedAnswers[i],
      });
    }

    await Provider.of<QuizProvider>(context, listen: false)
        .submitQuiz(widget.quizId, widget.studentId, answers);

    _showResult();
  }

  void _showResult() {
    int correctAnswers =
        scoreKeeper.where((icon) => icon.color == Colors.green).length;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Completed'),
          content: Text(
              'You got $correctAnswers out of ${selectedAnswers.length} correct!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
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

        final questions = quizData['questions'] as List<dynamic>;
        final currentQuestion = questions[currentQuestionIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text(quizData['title'] ?? 'Quiz'),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Question ${currentQuestionIndex + 1} of ${questions.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  currentQuestion['question'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
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
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        optionText,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  );
                }),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: scoreKeeper,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
