import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language/providers/quiz_provider.dart';
import 'package:language/components/question_card.dart';

class QuizCreationPage extends StatefulWidget {
  final String classId;

  const QuizCreationPage({super.key, required this.classId});

  @override
  _QuizCreationPageState createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  List<Map<String, dynamic>> _questions = [];
  final Set<int> _selectedQuestionIndices = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final quizProvider = context.read<QuizProvider>();
      final fetchedQuestions = await quizProvider.fetchQuestions();
      setState(() {
        _questions = fetchedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching questions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleQuestionSelection(int index) {
    setState(() {
      if (_selectedQuestionIndices.contains(index)) {
        _selectedQuestionIndices.remove(index);
      } else {
        _selectedQuestionIndices.add(index);
      }
    });
  }

  Future<void> _createQuiz(BuildContext context) async {
    if (_selectedQuestionIndices.isEmpty) {
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
      final endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        23,
        59,
        59,
      );
      setState(() => _isLoading = true);
      try {
        final quizProvider = context.read<QuizProvider>();
        final result = await quizProvider.createQuiz(
          widget.classId,
          _selectedQuestionIndices.toList(),
          endDate,
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz created successfully')),
          );
          setState(() => _isLoading = false);
          Navigator.pop(context);
        } else {
          setState(() => _isLoading = false);
          throw Exception('Failed to create quiz');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating quiz: $e')),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('No questions available'))
              : ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return QuestionCard(
                      questionText: question['questionText'] as String? ??
                          'Unknown question',
                      isSelected: _selectedQuestionIndices.contains(index),
                      onTap: () => _toggleQuestionSelection(index),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createQuiz(context),
        label: const Text('Create Quiz'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
