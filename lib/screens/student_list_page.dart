import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/class_provider.dart';
import '../providers/user_provider.dart';
import '../services/class_service.dart';

class StudentListPage extends StatefulWidget {
  final String classId;

  const StudentListPage({super.key, required this.classId});

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
        actions: [
          if (!isStudent)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) =>
                        RenameDialog(classId: widget.classId));
              },
            ),
          if (!isStudent)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Implement delete functionality
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Class'),
                      content: const Text(
                          'Are you sure you want to delete this class? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            classProvider.deleteClass(widget.classId);
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
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
                                radius: 15,
                                backgroundImage: (student["profileImageUrl"] !=
                                        null
                                    ? NetworkImage(student["profileImageUrl"]!)
                                    : null),
                                child: student["profileImageUrl"] == null
                                    ? const Icon(
                                        Icons.person,
                                      )
                                    : null,
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

class RenameDialog extends StatefulWidget {
  final String classId;

  const RenameDialog({super.key, required this.classId});

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  final TextEditingController classNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassProvider>(builder: (context, classProvider, child) {
      return AlertDialog(
        title: const Text('Rename Class'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: classNameController,
            decoration: const InputDecoration(
              labelText: 'New class name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a class name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await classProvider.renameClass(
                    classId: widget.classId,
                    newClassName: classNameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      );
    });
  }
}
