import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/class_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../providers/user_provider.dart';
import '../components/notice_card.dart';
import '../utils/ui_utils.dart';
import 'audio_submit_page.dart';

class PronunciationNotificationPage extends StatelessWidget {
  final String classId;

  const PronunciationNotificationPage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pronunciationProvider = Provider.of<PronunciationProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);

    final bool isStudent = userProvider.role == "Student";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: pronunciationProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pronunciationProvider.classPronunciations.isEmpty
                    ? const Center(child: Text('No Notifications Yet'))
                    : ListView.builder(
                        itemCount:
                            pronunciationProvider.classPronunciations.length,
                        itemBuilder: (context, index) {
                          // Reverse the index for display, but keep the original for data access
                          int reversedIndex =
                              pronunciationProvider.classPronunciations.length -
                                  1 -
                                  index;
                          var pronunciation = pronunciationProvider
                              .classPronunciations[reversedIndex];
                          bool isActive =
                              pronunciationProvider.isActive(pronunciation);
                          return FutureBuilder<bool>(
                            future: pronunciationProvider.isPronunciationDone(
                                classId, reversedIndex),
                            builder: (context, snapshot) {
                              bool isDone = snapshot.data ?? false;

                              return FutureBuilder<int>(
                                future: pronunciationProvider
                                    .getPronunciationSubmissionCount(
                                        classId, reversedIndex),
                                builder: (context, submissionSnapshot) {
                                  int submissionCount =
                                      submissionSnapshot.data ?? 0;

                                  return NoticeCard(
                                    titleText:
                                        'Pronunciation ${reversedIndex + 1}',
                                    isActive: isActive,
                                    completionNum: submissionCount,
                                    isDone: isDone,
                                    chipText: isActive
                                        ? 'Deadline: ${_formatDate(pronunciation['dateEnd'].toDate())}'
                                        : 'Deadline Reached: ${_formatDate(pronunciation['dateEnd'].toDate())}',
                                    smallText:
                                        'Created at ${_formatDate(pronunciation['dateCreated'].toDate())}',
                                    isStudent: isStudent,
                                    totalStudents: classProvider.totalStudents,
                                    onPressed: () {
                                      if (isStudent) {
                                        if (isDone) {
                                          UIUtils.showToast(
                                              "Already submitted");
                                        } else {
                                          if (isActive) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider<
                                                        AudioProvider>(
                                                  create: (context) =>
                                                      AudioProvider(),
                                                  child: AudioSubmitPage(
                                                    classId: classId,
                                                    pronunciationIndex:
                                                        reversedIndex,
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            UIUtils.showToast(
                                                "Deadline reached");
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
