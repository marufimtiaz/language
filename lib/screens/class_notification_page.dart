import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../components/notice_card.dart';
import '../utils/ui_utils.dart';
import 'quiz_submission_page.dart';

class ClassNoticePage extends StatelessWidget {
  final String classId;

  const ClassNoticePage({Key? key, required this.classId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final quizProvider = Provider.of<QuizProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);

    final bool isStudent = userProvider.role == "Student";
    final String userId = userProvider.userId!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: quizProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : quizProvider.quizzes.isEmpty
                    ? const Center(child: Text('No Notifications Yet'))
                    : ListView.builder(
                        itemCount: quizProvider.quizzes.length,
                        itemBuilder: (context, index) {
                          // Reverse the index for display, but keep the original for data access
                          int reversedIndex =
                              quizProvider.quizzes.length - 1 - index;
                          var quiz = quizProvider.quizzes[reversedIndex];
                          bool isActive = quizProvider.isActive(quiz);
                          return FutureBuilder<bool>(
                            future:
                                quizProvider.isQuizDone(classId, reversedIndex),
                            builder: (context, snapshot) {
                              bool isDone = snapshot.data ?? false;

                              return FutureBuilder<int>(
                                future: quizProvider.getQuizSubmissionCount(
                                    classId, reversedIndex),
                                builder: (context, submissionSnapshot) {
                                  int submissionCount =
                                      submissionSnapshot.data ?? 0;

                                  return NoticeCard(
                                    titleText: 'Quiz ${reversedIndex + 1}',
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
                                          if (isActive) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuizSubmissionPage(
                                                  classId: classId,
                                                  quizIndex: reversedIndex,
                                                  studentId: userId,
                                                ),
                                              ),
                                            );
                                          } else {
                                            UIUtils.showToast(
                                                "Quiz deadline reached");
                                          }
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
    );
  }

  String _formatDate(DateTime date) {
    int hour = date.hour > 12 ? date.hour - 12 : date.hour;
    hour = hour == 0 ? 12 : hour; // Handle midnight and noon cases
    return "${date.day} ${_getMonthName(date.month)}; $hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
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
}
