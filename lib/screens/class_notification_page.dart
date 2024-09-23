import 'package:flutter/material.dart';
import 'package:language/screens/audio_record_page.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../components/notice_card.dart';
import '../services/class_service.dart';
import '../services/quiz_service.dart'; // Import QuizService
import '../providers/audio_provider.dart';
import 'create_quiz_page.dart';
import 'quiz_submission_page.dart';
import 'student_list_page.dart';
import '../utils/ui_utils.dart';
import 'translator_page.dart';

class ClassNoticePage extends StatelessWidget {
  final String classId;

  const ClassNoticePage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bool isStudent = userProvider.role == "Student";
    final String userId = userProvider.user!.uid;

    QuizService quizService = QuizService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
              icon: const Icon(Icons.translate_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TranslatorPage()),
                );
              }),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentListPage(classId: classId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: QuizService().getClassQuizzes(classId).map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error fetching quizzes"));
          }

          var quizzes = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      var quiz = quizzes[index];
                      bool isActive =
                          DateTime.now().isBefore(quiz['endDate'].toDate());
                      return FutureBuilder<bool>(
                        future: quizService.isQuizDone(quiz['quizId'],
                            userId), // Replace studentId with the actual student ID
                        builder: (context, snapshot) {
                          bool isDone = snapshot.data ?? false;

                          return FutureBuilder<int>(
                            future: ClassService().getTotalStudents(
                                classId), // Replace classId with the actual class ID
                            builder: (context, totalStudentsSnapshot) {
                              int totalStudents =
                                  totalStudentsSnapshot.data ?? 0;

                              return NoticeCard(
                                titleText: 'Quiz ${index + 1}',
                                isActive: isActive,
                                completionNum: quiz['doneCount'] ?? 0,
                                isDone: isDone,
                                chipText: isActive
                                    ? 'Deadline: ${_formatDate(quiz['endDate'].toDate())}'
                                    : 'Deadline Reached: ${_formatDate(quiz['endDate'].toDate())}',
                                smallText:
                                    'Created at ${_formatDate(quiz['dateCreated'].toDate())}',
                                isStudent: isStudent,
                                totalStudents: totalStudents,
                                onPressed: () => isStudent
                                    ? {
                                        isDone
                                            ? UIUtils.showToast(
                                                "Quiz already submitted")
                                            : Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuizSubmissionPage(
                                                    quizId: quiz['quizId'],
                                                    studentId: userId,
                                                  ),
                                                ),
                                              ),
                                      }
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isStudent
          ? null
          : FloatingActionButton(
              onPressed: () => _showOptionsDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_getMonthName(date.month)}; ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
  }

  String _getMonthName(int month) {
    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return monthNames[month - 1];
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            CreateQuizPage(classId: classId)));
                  },
                  child: const Text('Quiz'),
                ),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                            create: (context) => AudioProvider(),
                            child: const AudioRecordingPage())));
                  },
                  child: const Text('Pronunciation Challenge'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// PageOne and PageTwo classes remain unchanged

// PageOne and PageTwo classes remain unchanged

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page One')),
      body: const Center(child: Text('Welcome to Page One!')),
    );
  }
}

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Two')),
      body: const Center(child: Text('Welcome to Page Two!')),
    );
  }
}
