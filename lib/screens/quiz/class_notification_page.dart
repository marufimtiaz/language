import 'package:flutter/material.dart';
import 'package:language/screens/quiz/quiz_submission_list.dart';
import 'package:provider/provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../components/notice_card.dart';
import '../../utils/ui_utils.dart';
import 'quiz_score_page.dart';
import 'quiz_submission_page.dart';

class ClassNoticePage extends StatefulWidget {
  final String classId;

  const ClassNoticePage({super.key, required this.classId});

  @override
  State<ClassNoticePage> createState() => _ClassNoticePageState();
}

class _ClassNoticePageState extends State<ClassNoticePage> {
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
                            future: quizProvider.isQuizDone(
                                widget.classId, reversedIndex),
                            builder: (context, snapshot) {
                              bool isDone = snapshot.data ?? false;

                              return FutureBuilder<int>(
                                future: quizProvider.getQuizSubmissionCount(
                                    widget.classId, reversedIndex),
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
                                    dateChange: () {
                                      //show datepicker
                                      isStudent
                                          ? null
                                          : _changeEndDate(
                                              quiz['dateEnd'].toDate(),
                                              reversedIndex,
                                              isActive);
                                    },
                                    onPressed: () {
                                      if (isStudent) {
                                        if (isDone) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuizScorePage(
                                                        classId: widget.classId,
                                                        quizIndex:
                                                            reversedIndex,
                                                      )));
                                        } else {
                                          if (isActive) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuizSubmissionPage(
                                                  classId: widget.classId,
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
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  QuizDetailsPage(
                                                      classId: widget.classId,
                                                      quizIndex:
                                                          reversedIndex)),
                                        );
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

  Future<void> _changeEndDate(
      DateTime date, int quizIndex, bool isActive) async {
    DateTime? endDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isActive ? date : DateTime.now(),
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

      final result = await quizProvider.updateQuizDate(
          widget.classId, quizIndex, endDate!);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadline updated')),
        );
        // Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating deadline')),
        );
      }
    }
  }
}
