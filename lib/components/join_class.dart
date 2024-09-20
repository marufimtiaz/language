import 'package:flutter/material.dart';
import '../services/class_service.dart';

class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({super.key});

  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final TextEditingController classIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ClassService _classService = ClassService();
  bool isLoading = false;
  bool isJoined = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Join a Class"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isJoined) ...[
              TextFormField(
                controller: classIdController,
                decoration: const InputDecoration(labelText: "Enter Class ID"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Class ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text("Joining class, please wait..."),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _joinClass(context);
                        }
                      },
                      child: const Text("Join Class"),
                    ),
            ] else ...[
              const Text("Successfully Joined"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _joinClass(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    bool joined = await _classService.joinClass(classIdController.text);

    setState(() {
      isLoading = false;
      isJoined = joined;
    });

    if (!joined) {
      setState(() {
        isJoined = false;
      });
    }
  }
}
