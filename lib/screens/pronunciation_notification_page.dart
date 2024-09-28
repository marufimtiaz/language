import 'package:flutter/material.dart';
import 'package:language/providers/audio_provider.dart';
import 'package:language/screens/add_questions.dart';
import 'package:language/screens/pronunciation_list.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../components/notice_card.dart';
import '../utils/ui_utils.dart';
import 'audio_submit_page.dart';
import 'create_quiz_page.dart';
import 'student_list_page.dart';
import 'translator_page.dart';

class PronunciationNotificationPage extends StatefulWidget {
  final String classId;

  const PronunciationNotificationPage({super.key, required this.classId});

  @override
  State<PronunciationNotificationPage> createState() =>
      PronunciationNotificationPageState();
}

class PronunciationNotificationPageState
    extends State<PronunciationNotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pronunciationProvider =
          Provider.of<PronunciationProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      classProvider.getStudentList(classId: widget.classId);
      pronunciationProvider.fetchClassPronunciations(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pronunciationProvider = Provider.of<PronunciationProvider>(context);
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
              child: pronunciationProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : pronunciationProvider.classPronunciations.isEmpty
                      ? const Center(child: Text('No Notifications Yet'))
                      : ListView.builder(
                          itemCount:
                              pronunciationProvider.classPronunciations.length,
                          itemBuilder: (context, index) {
                            var pronunciation = pronunciationProvider
                                .classPronunciations[index];
                            bool isActive =
                                pronunciationProvider.isActive(pronunciation);
                            return FutureBuilder<bool>(
                              future: pronunciationProvider.isPronunciationDone(
                                  widget.classId, index),
                              builder: (context, snapshot) {
                                bool isDone = snapshot.data ?? false;

                                return FutureBuilder<int>(
                                  future: pronunciationProvider
                                      .getPronunciationSubmissionCount(
                                          widget.classId, index),
                                  builder: (context, submissionSnapshot) {
                                    int submissionCount =
                                        submissionSnapshot.data ?? 0;

                                    return NoticeCard(
                                      titleText: 'Pronunciation ${index + 1}',
                                      isActive: isActive,
                                      completionNum: submissionCount,
                                      isDone: isDone,
                                      chipText: isActive
                                          ? 'Deadline: ${_formatDate(pronunciation['dateEnd'].toDate())}'
                                          : 'Deadline Reached: ${_formatDate(pronunciation['dateEnd'].toDate())}',
                                      smallText:
                                          'Created at ${_formatDate(pronunciation['dateCreated'].toDate())}',
                                      isStudent: isStudent,
                                      totalStudents:
                                          classProvider.totalStudents,
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
                                                      classId: widget.classId,
                                                      pronunciationIndex: index,
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
                  child:
                      const Text('Quiz', style: TextStyle(color: Colors.black)),
                ),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PronunciationListPage(
                        classId: widget.classId,
                      ),
                    ));
                  },
                  child: const Text('Pronunciation Challenge',
                      style: TextStyle(color: Colors.black)),
                ),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AddQuestionPage(),
                    ));
                  },
                  child: const Text('Add Questions',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
