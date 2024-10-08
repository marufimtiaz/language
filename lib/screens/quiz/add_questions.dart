import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  _AddQuestionPageState createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(3, (_) => TextEditingController());
  int _correctAnswerIndex = 0;

  Future<void> _submitQuestion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final questionMap = {
          'questionText': _questionController.text,
          'options': _optionControllers.map((c) => c.text).toList(),
          'answer': _correctAnswerIndex,
        };

        await FirebaseFirestore.instance
            .collection('questions')
            .doc('FREEQUESTIONS')
            .update({
          'questionSet': FieldValue.arrayUnion([questionMap])
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question added successfully!')),
        );

        // Clear the form
        _questionController.clear();
        for (var controller in _optionControllers) {
          controller.clear();
        }
        setState(() {
          _correctAnswerIndex = 0;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding question: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add New Question')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a question' : null,
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _optionControllers[index],
                      decoration:
                          InputDecoration(labelText: 'Option ${index + 1}'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an option' : null,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _correctAnswerIndex,
                  items: List.generate(3, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text('Option ${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _correctAnswerIndex = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Correct Answer'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitQuestion,
                  child: const Text('Add Question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
