import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language/providers/quiz_provider.dart';
import 'package:language/components/question_card.dart';

class QuizCreationPage extends StatefulWidget {
  final String classId;

  const QuizCreationPage({super.key, required this.classId});

  @override
  State<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  List<Map<String, dynamic>>? questions;
  List<int> selectedQuestionIndices = [];
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final fetchedQuestions = await quizProvider.fetchQuestions();
    setState(() {
      questions = fetchedQuestions;
    });
  }

  void _toggleQuestionSelection(int index) {
    setState(() {
      if (selectedQuestionIndices.contains(index)) {
        selectedQuestionIndices.remove(index);
      } else {
        selectedQuestionIndices.add(index);
      }
    });
  }

  Future<void> _pickEndDate() async {
    if (selectedQuestionIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select questions first')),
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(
        () {
          endDate = DateTime(
              pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
        },
      );

      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      final result = await quizProvider.createQuiz(
          widget.classId, selectedQuestionIndices, endDate!);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating quiz')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: questions == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: questions!.length,
                      itemBuilder: (context, index) {
                        final question = questions![index];
                        return QuestionCard(
                          questionText: question['questionText'] as String,
                          isSelected: selectedQuestionIndices.contains(index),
                          onTap: () => _toggleQuestionSelection(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickEndDate,
        label: const Text('Create Quiz'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
