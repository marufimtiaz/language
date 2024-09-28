import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../components/notice_card.dart';
import '../utils/ui_utils.dart';
import 'create_quiz_page.dart';
import 'pronunciation_list.dart';
import 'quiz_submission_page.dart';
import 'audio_submit_page.dart';
import 'student_list_page.dart';
import 'translator_page.dart';
import 'add_questions.dart';

class CombinedNoticePage extends StatefulWidget {
  final String classId;

  const CombinedNoticePage({Key? key, required this.classId}) : super(key: key);

  @override
  State<CombinedNoticePage> createState() => _CombinedNoticePageState();
}

class _CombinedNoticePageState extends State<CombinedNoticePage> {
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final pronunciationProvider =
        Provider.of<PronunciationProvider>(context, listen: false);
    final classProvider = Provider.of<ClassProvider>(context, listen: false);

    await Future.wait([
      classProvider.getStudentList(classId: widget.classId),
      quizProvider.fetchQuizList(widget.classId),
      pronunciationProvider.fetchClassPronunciations(widget.classId),
    ]);

    List<Map<String, dynamic>> combinedItems = [
      ...quizProvider.quizzes.map((quiz) => {...quiz, 'type': 'quiz'}),
      ...pronunciationProvider.classPronunciations
          .map((pronunciation) => {...pronunciation, 'type': 'pronunciation'}),
    ];
    combinedItems.sort((a, b) => b['dateCreated'].compareTo(a['dateCreated']));

    return combinedItems;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final quizProvider = Provider.of<QuizProvider>(context);
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
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            _dataFuture = _fetchData();
          });
          return _dataFuture;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No Notifications Yet'));
            } else {
              List<Map<String, dynamic>> combinedItems = snapshot.data!;
              return ListView.builder(
                itemCount: combinedItems.length,
                itemBuilder: (context, index) {
                  var item = combinedItems[index];
                  bool isQuiz = item['type'] == 'quiz';
                  bool isActive = isQuiz
                      ? quizProvider.isActive(item)
                      : pronunciationProvider.isActive(item);

                  return FutureBuilder<bool>(
                    future: isQuiz
                        ? quizProvider.isQuizDone(
                            widget.classId, quizProvider.quizzes.indexOf(item))
                        : pronunciationProvider.isPronunciationDone(
                            widget.classId,
                            pronunciationProvider.classPronunciations
                                .indexOf(item)),
                    builder: (context, snapshot) {
                      bool isDone = snapshot.data ?? false;

                      return FutureBuilder<int>(
                        future: isQuiz
                            ? quizProvider.getQuizSubmissionCount(
                                widget.classId,
                                quizProvider.quizzes.indexOf(item))
                            : pronunciationProvider
                                .getPronunciationSubmissionCount(
                                    widget.classId,
                                    pronunciationProvider.classPronunciations
                                        .indexOf(item)),
                        builder: (context, submissionSnapshot) {
                          int submissionCount = submissionSnapshot.data ?? 0;

                          return NoticeCard(
                            titleText: isQuiz
                                ? 'Quiz Challenge ${quizProvider.quizzes.indexOf(item) + 1}'
                                : 'Pronunciation Challenge',
                            // ? 'Quiz Challenge ${quizProvider.quizzes.indexOf(item) + 1}'
                            // : 'Pronunciation Challenge ${pronunciationProvider.classPronunciations.indexOf(item) + 1}',
                            isActive: isActive,
                            completionNum: submissionCount,
                            isDone: isDone,
                            chipText: isActive
                                ? 'Deadline: ${_formatDate(item['dateEnd'].toDate())}'
                                : 'Deadline Reached: ${_formatDate(item['dateEnd'].toDate())}',
                            smallText:
                                'Created at ${_formatDate(item['dateCreated'].toDate())}',
                            isStudent: isStudent,
                            totalStudents: classProvider.totalStudents,
                            onPressed: () {
                              if (isStudent) {
                                if (isDone) {
                                  UIUtils.showToast(
                                      "${isQuiz ? 'Quiz' : 'Pronunciation'} already submitted");
                                } else {
                                  if (isActive) {
                                    isQuiz
                                        ? Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    QuizSubmissionPage(
                                                      classId: widget.classId,
                                                      quizIndex: quizProvider
                                                          .quizzes
                                                          .indexOf(item),
                                                      studentId: userId,
                                                    )),
                                          )
                                        : Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChangeNotifierProvider(
                                                create: (context) =>
                                                    AudioProvider(),
                                                child: AudioSubmitPage(
                                                  classId: widget.classId,
                                                  pronunciationIndex:
                                                      pronunciationProvider
                                                          .classPronunciations
                                                          .indexOf(item),
                                                ),
                                              ),
                                            ),
                                          );
                                  } else {
                                    UIUtils.showToast(
                                        "${isQuiz ? 'Quiz' : 'Pronunciation'} deadline reached");
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
              );
            }
          },
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
