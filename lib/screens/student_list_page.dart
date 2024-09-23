import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../services/class_service.dart';

class StudentListPage extends StatefulWidget {
  final String classId;

  const StudentListPage({Key? key, required this.classId}) : super(key: key);

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      classProvider.getStudentList(classId: widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final userProvider = Provider.of<UserProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);

    final bool isStudent = userProvider.role == "Student";

    print(
        'Building StudentListPage. isLoading: ${classProvider.isLoading}, studentList length: ${classProvider.studentList.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Details'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: primaryColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Class code: ${widget.classId}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: onPrimaryColor,
                        ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: onPrimaryColor),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.classId));
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Student List", style: Theme.of(context).textTheme.titleLarge),
            Text("Total ${classProvider.totalStudents} students",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16.0),
            Expanded(
              child: classProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : classProvider.studentList.isEmpty
                      ? const Center(
                          child: Text("No students in this class yet."))
                      : ListView.separated(
                          itemCount: classProvider.studentList.length,
                          itemBuilder: (context, index) {
                            var student = classProvider.studentList[index];
                            print('Rendering student: $student');
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    "https://randomuser.me/api/portraits/men/${index.toString()}.jpg"),
                              ),
                              title: Text(student["name"] ?? "Unknown"),
                              subtitle: Text(student["email"] ?? "No email"),
                              trailing: isStudent
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await ClassService()
                                            .removeStudentFromClass(
                                                widget.classId,
                                                student['id'] ?? "");
                                        classProvider.getStudentList(
                                            classId: widget.classId);
                                      },
                                    ),
                            );
                          },
                          separatorBuilder: (context, index) => const Divider(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
