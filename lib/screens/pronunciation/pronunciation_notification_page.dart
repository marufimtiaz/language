import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/list_audio_provider.dart';
import '../../providers/pronunciation_provider.dart';
import '../../providers/user_provider.dart';
import '../../components/notice_card.dart';
import '../../utils/ui_utils.dart';
import 'audio_submit_page.dart';
import 'pronunciation_score_page.dart';
import 'pronunciation_submission_list.dart';

class PronunciationNotificationPage extends StatefulWidget {
  final String classId;

  const PronunciationNotificationPage({super.key, required this.classId});

  @override
  State<PronunciationNotificationPage> createState() =>
      _PronunciationNotificationPageState();
}

class _PronunciationNotificationPageState
    extends State<PronunciationNotificationPage> {
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
                                widget.classId, reversedIndex),
                            builder: (context, snapshot) {
                              bool isDone = snapshot.data ?? false;

                              return FutureBuilder<int>(
                                future: pronunciationProvider
                                    .getPronunciationSubmissionCount(
                                        widget.classId, reversedIndex),
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
                                    dateChange: () {
                                      //show datepicker
                                      isStudent
                                          ? null
                                          : _changeEndDate(
                                              pronunciation['dateEnd'].toDate(),
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
                                                  PronunciationScorePage(
                                                classId: widget.classId,
                                                pronunciationIndex:
                                                    reversedIndex,
                                              ),
                                            ),
                                          );
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
                                                    classId: widget.classId,
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
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider<
                                                    ListAudioProvider>(
                                              create: (context) =>
                                                  ListAudioProvider(),
                                              child:
                                                  PronunciationSubmissionList(
                                                      classId: widget.classId,
                                                      pronunciationIndex:
                                                          reversedIndex),
                                            ),
                                          ),
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
      DateTime date, int pronunciationIndex, bool isActive) async {
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
      bool result =
          await Provider.of<PronunciationProvider>(context, listen: false)
              .updatePronunciationDate(
                  widget.classId, pronunciationIndex, endDate!);
      if (result) {
        UIUtils.showToast("Deadline updated");
      } else {
        UIUtils.showToast("Error updating deadline");
      }
    }
  }
}
