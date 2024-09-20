import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:language/auth/auth_service.dart';
import 'package:language/components/class_card.dart';
import 'package:language/components/join_class.dart';
import 'package:language/screens/translator_page.dart';
import 'package:provider/provider.dart';
import '../auth/user_provider.dart'; // Your UserProvider class
import '../services/class_service.dart';
import '../components/create_class.dart';
import 'class_notification_page.dart'; // Import auth service for sign out

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    String? role = userProvider.role;

    return role == "Teacher"
        ? const TeacherHomepage()
        : const StudentHomepage();
  }
}

class TeacherHomepage extends StatelessWidget {
  const TeacherHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseHomepage(
      title: "Teacher Homepage",
      fabBuilder: (context) => FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) => const CreateClassDialog(),
        ),
        label: const Text('Add Class'),
        icon: const Icon(Icons.add),
      ),
      classesStream: (userId) => ClassService().getTeacherClasses(userId),
    );
  }
}

class StudentHomepage extends StatelessWidget {
  const StudentHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseHomepage(
      title: "Student Homepage",
      fabBuilder: (context) => FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) => const JoinClassDialog(),
        ),
        label: const Text('Join Class'),
        icon: const Icon(Icons.add),
      ),
      classesStream: (userId) => ClassService().getStudentClasses(userId),
    );
  }
}

class BaseHomepage extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext) fabBuilder;
  final Stream<QuerySnapshot> Function(String?) classesStream;

  const BaseHomepage({
    super.key,
    required this.title,
    required this.fabBuilder,
    required this.classesStream,
  });

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
              icon: const Icon(Icons.translate_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TranslatorPage()),
                );
              }),
          const IconButton(
            icon: Icon(Icons.logout),
            onPressed: signOutUser,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: classesStream(user?.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error fetching classes: ${snapshot.error}"));
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No classes available."));
                }
                return ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClassCard(
                        titleText: doc['name'],
                        leftSubText:
                            "${(doc['studentIds'] as List).length} Students",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ClassNoticePage(classId: doc.id)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: fabBuilder(context),
    );
  }
}

// String _formatDate(Timestamp? timestamp) {
//   if (timestamp == null) return 'N/A';
//   DateTime dateTime = timestamp.toDate();
//   return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
// }
