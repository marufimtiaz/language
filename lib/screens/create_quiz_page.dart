import 'package:flutter/material.dart';
import '../services/quiz_service.dart';

class CreateQuizPage extends StatefulWidget {
  final String classId;

  const CreateQuizPage({super.key, required this.classId});

  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  List<GlobalKey<_QuestionCardState>> questionKeys = [
    GlobalKey<_QuestionCardState>()
  ];
  final QuizService _quizService = QuizService();

  void addQuestionCard() {
    setState(() {
      questionKeys.insert(0, GlobalKey<_QuestionCardState>());
    });
  }

  void removeQuestionCard(int index) {
    setState(() {
      questionKeys.removeAt(index);
    });
  }

  Future<void> saveQuiz() async {
    // Validate all question cards
    bool isValid =
        questionKeys.every((key) => key.currentState?.isValid() ?? false);
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select correct answers')),
      );
      return;
    }

    // Show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Confirm quiz creation
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Quiz Creation'),
            content: const Text('Are you sure you want to create this quiz?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        // Create quiz
        List<Map<String, dynamic>> questions =
            questionKeys.map((key) => key.currentState?.toMap() ?? {}).toList();
        String? quizId = await _quizService.createQuiz(
            widget.classId, questions, pickedDate);
        if (quizId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz created successfully')),
          );
          Navigator.of(context).pop(); // Return to previous page
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz')),
      body: ListView(
        children: [
          ...questionKeys.asMap().entries.map((entry) {
            int idx = entry.key;
            GlobalKey<_QuestionCardState> key = entry.value;
            return Dismissible(
              key: Key('question_$idx'),
              onDismissed: (_) => removeQuestionCard(idx),
              child: QuestionCard(key: key),
            );
          }).toList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: addQuestionCard,
            child: const Text('Add Question'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveQuiz,
            child: const Text('Save Quiz'),
          ),
        ],
      ),
    );
  }
}

class QuestionCard extends StatefulWidget {
  const QuestionCard({super.key});

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  int? correctAnswerIndex;

  bool isValid() {
    return questionController.text.isNotEmpty &&
        optionControllers.every((controller) => controller.text.isNotEmpty) &&
        correctAnswerIndex != null;
  }

  Map<String, dynamic> toMap() {
    return {
      'question': questionController.text,
      'options':
          optionControllers.map((controller) => controller.text).toList(),
      'correctAnswer': correctAnswerIndex,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: questionController,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            ...List.generate(4, (index) {
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: optionControllers[index],
                      decoration:
                          InputDecoration(labelText: 'Option ${index + 1}'),
                    ),
                  ),
                  Radio<int>(
                    value: index,
                    groupValue: correctAnswerIndex,
                    onChanged: (int? value) {
                      setState(() {
                        correctAnswerIndex = value;
                      });
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
