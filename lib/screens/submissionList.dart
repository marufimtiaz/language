import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language/providers/quiz_provider.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../services/class_service.dart';
import 'homepage.dart';

class QuizDetailsPage extends StatefulWidget {
  final String classId;
  final int quizIndex;

  const QuizDetailsPage(
      {super.key, required this.classId, required this.quizIndex});

  @override
  State<QuizDetailsPage> createState() => _QuizDetailsPageState();
}

class _QuizDetailsPageState extends State<QuizDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.getStudentList(
          classId: widget.classId, quizIndex: widget.quizIndex);
      quizProvider.getScores(widget.classId, widget.quizIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final quizProvider = Provider.of<QuizProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Implement delete functionality
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Quiz'),
                    content: const Text(
                        'Are you sure you want to delete this quiz? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Delete quiz
                          quizProvider.deleteQuiz(
                              widget.classId, widget.quizIndex);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await quizProvider.getStudentList(
              classId: widget.classId, quizIndex: widget.quizIndex);
          await quizProvider.getScores(widget.classId, widget.quizIndex);
          print('Total students: ${quizProvider.totalStudents}, '
              'Student list: ${quizProvider.studentList}, '
              'Scores: ${quizProvider.scores}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Student List",
                  style: Theme.of(context).textTheme.titleLarge),
              Text("Total ${quizProvider.totalStudents} submissions",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16.0),
              Expanded(
                child: _buildStudentList(quizProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList(QuizProvider quizProvider) {
    if (quizProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (quizProvider.studentList.isEmpty) {
      return const Center(
          child: Text("No students have submitted this quiz yet."));
    } else {
      return ListView.builder(
        itemCount: quizProvider.studentList.length,
        itemBuilder: (context, index) {
          var student = quizProvider.studentList[index];
          var score = quizProvider.scores.length > index
              ? quizProvider.scores[index]
              : null;
          return ListTile(
            leading: CircleAvatar(
              radius: 15,
              backgroundImage: student["profileImageUrl"] != null
                  ? NetworkImage(student["profileImageUrl"]!)
                  : null,
              child: student["profileImageUrl"] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(student["name"] ?? "Unknown",
                style: const TextStyle(fontSize: 18)),
            trailing: score != null
                ? Text("$score points", style: const TextStyle(fontSize: 12))
                : null,
          );
        },
      );
    }
  }
}
