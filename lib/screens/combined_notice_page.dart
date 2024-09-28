import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/pronunciation_provider.dart';
import 'class_notification_page.dart';
import 'pronunciation_list.dart';
import 'pronunciation_notification_page.dart';
import 'translator_page.dart';
import 'student_list_page.dart';
import 'create_quiz_page.dart';
import 'add_questions.dart';

class TabbedNotificationsPage extends StatefulWidget {
  final String classId;

  const TabbedNotificationsPage({Key? key, required this.classId})
      : super(key: key);

  @override
  _TabbedNotificationsPageState createState() =>
      _TabbedNotificationsPageState();
}

class _TabbedNotificationsPageState extends State<TabbedNotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final pronunciationProvider =
          Provider.of<PronunciationProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);

      classProvider.getStudentList(classId: widget.classId);
      quizProvider.fetchQuizList(widget.classId);
      pronunciationProvider.fetchClassPronunciations(widget.classId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isStudent = userProvider.role == "Student";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quizzes'),
            Tab(text: 'Pronunciation'),
          ],
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          ClassNoticePage(classId: widget.classId),
          PronunciationNotificationPage(classId: widget.classId),
        ],
      ),
      floatingActionButton: isStudent
          ? null
          : FloatingActionButton(
              onPressed: () => _showOptionsDialog(context),
              child: const Icon(Icons.add),
            ),
    );
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
                  child: const Text(
                    'Quiz',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
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
                      style: TextStyle(color: Colors.black, fontSize: 16)),
                ),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AddQuestionPage(),
                    ));
                  },
                  child: const Text('Add Questions',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
