import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/class_provider.dart';
import '../components/class_card.dart';
import '../components/create_class.dart';
import '../components/join_class.dart';
import 'class_notification_page.dart';
import 'translator_page.dart';
import '../auth/auth_check.dart';
import '../auth/auth_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      if (!classProvider.isLoading && classProvider.classes.isEmpty) {
        classProvider.fetchClasses(userProvider.userId!, userProvider.role!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    String? role = userProvider.role;

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!classProvider.isLoading && classProvider.classes.isEmpty) {
      classProvider.fetchClasses(userProvider.userId!, userProvider.role!);
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(role == 'Teacher' ? "Teacher Homepage" : "Student Homepage"),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TranslatorPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              signOutUser(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthCheck()),
              );
            },
          ),
        ],
      ),
      body: classProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : classProvider.classes.isEmpty
              ? const Center(child: Text("No classes available."))
              : ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 0),
                  itemCount: classProvider.classes.length,
                  itemBuilder: (context, index) {
                    var classData = classProvider.classes[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClassCard(
                        titleText: classData['name'],
                        leftSubText:
                            "${(classData['studentIds'] as List).length} Students",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassNoticePage(
                                  classId: classData['classId']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) => role == 'Teacher'
              ? const CreateClassDialog()
              : const JoinClassDialog(),
        ),
        label: role == 'Teacher'
            ? const Text('Add Class')
            : const Text('Join Class'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
