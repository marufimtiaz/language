import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/class_service.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController dateEndController = TextEditingController();
  final ClassService _classService = ClassService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _classId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Create New Class",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_classId == null) ...[
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: classNameController,
                  decoration: const InputDecoration(labelText: "Class Name"),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _isLoading
                ? const CircularProgressIndicator()
                : _classId != null
                    ? Column(
                        children: [
                          const Text(
                            "Class Created",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text("Class ID: $_classId"),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: const Text("OK"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: _classId ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Class ID copied to clipboard"),
                                    ),
                                  );
                                },
                                child: const Text("Copy"),
                              ),
                            ],
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _createClass(context);
                          }
                        },
                        child: const Text("Create Class"),
                      ),
          ],
        ),
      ),
    );
  }

  Future<void> _createClass(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    String? classId = await _classService.createClass(
      classNameController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _classId = classId;
      });
    }
  }
}
