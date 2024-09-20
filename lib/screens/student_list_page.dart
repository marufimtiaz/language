import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../auth/user_provider.dart';
import '../services/class_service.dart';

class StudentListPage extends StatelessWidget {
  final String classId;

  const StudentListPage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final userProvider = Provider.of<UserProvider>(context);
    final bool isStudent = userProvider.role == "Student";

    return Scaffold(
        appBar: AppBar(
          title: const Text('Class Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {
                // Consider removing this if it's not needed
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder<Map<String, dynamic>>(
                      stream: ClassService().getClassStream(classId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text("Error loading class");
                        }

                        return Text(
                          "Class code: $classId",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: onPrimaryColor,
                                  ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: onPrimaryColor),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: classId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Class code copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: ClassService().getClassStream(classId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text("Error fetching class details"));
            }

            var classData = snapshot.data!;
            List<Map<String, dynamic>> studentDetails =
                List<Map<String, dynamic>>.from(
                    classData['studentDetails'] ?? []);
            int totalStudents = studentDetails.length;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Student List",
                      style: Theme.of(context).textTheme.titleLarge),
                  Text("Total $totalStudents students",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: ListView.separated(
                      itemCount: studentDetails.length,
                      itemBuilder: (context, index) {
                        var student = studentDetails[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                "https://randomuser.me/api/portraits/men/${index.toString()}.jpg"),
                          ),
                          title: Text(student["name"]!),
                          subtitle: Text(student["email"]!),
                          trailing: isStudent
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await ClassService().removeStudentFromClass(
                                        classId, student['id']);
                                  },
                                ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(),
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }
}
