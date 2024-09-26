import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../components/notice_card.dart';
import '../utils/ui_utils.dart';
import 'create_quiz_page.dart';
import 'quiz_submission_page.dart';
import 'student_list_page.dart';
import 'translator_page.dart';
import 'audio_record_page.dart';

class ClassNoticePage extends StatefulWidget {
  final String classId;

  const ClassNoticePage({super.key, required this.classId});

  @override
  State<ClassNoticePage> createState() => _ClassNoticePageState();
}

class _ClassNoticePageState extends State<ClassNoticePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      classProvider.getStudentList(classId: widget.classId);
      quizProvider.fetchQuizList(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final quizProvider = Provider.of<QuizProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);

    final bool isStudent = userProvider.role == "Student";
    final String userId = userProvider.userId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TranslatorPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentListPage(classId: widget.classId),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: quizProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: quizProvider.quizzes.length,
                      itemBuilder: (context, index) {
                        var quiz = quizProvider.quizzes[index];
                        bool isActive = quizProvider.isActive(quiz);
                        return FutureBuilder<bool>(
                          future:
                              quizProvider.isQuizDone(widget.classId, index),
                          builder: (context, snapshot) {
                            bool isDone = snapshot.data ?? false;

                            return FutureBuilder<int>(
                              future: quizProvider.getQuizSubmissionCount(
                                  widget.classId, index),
                              builder: (context, submissionSnapshot) {
                                int submissionCount =
                                    submissionSnapshot.data ?? 0;

                                return NoticeCard(
                                  titleText: 'Quiz ${index + 1}',
                                  isActive: isActive,
                                  completionNum: submissionCount,
                                  isDone: isDone,
                                  chipText: isActive
                                      ? 'Deadline: ${_formatDate(quiz['dateEnd'].toDate())}'
                                      : 'Deadline Reached: ${_formatDate(quiz['dateEnd'].toDate())}',
                                  smallText:
                                      'Created at ${_formatDate(quiz['dateCreated'].toDate())}',
                                  isStudent: isStudent,
                                  totalStudents: classProvider.totalStudents,
                                  onPressed: () {
                                    if (isStudent) {
                                      if (isDone) {
                                        UIUtils.showToast(
                                            "Quiz already submitted");
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                QuizSubmissionPage(
                                              classId: widget.classId,
                                              quizIndex: index,
                                              studentId: userId,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
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
                          QuizCreationPage(classId: widget.classId),
                    ));
                  },
                  child: const Text('Quiz'),
                ),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (context) => AudioProvider(),
                        child: const AudioRecordingPage(),
                      ),
                    ));
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
