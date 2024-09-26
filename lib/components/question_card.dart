import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String questionText;
  final bool isSelected;
  final VoidCallback onTap;

  const QuestionCard({
    super.key,
    required this.questionText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? Colors.green : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            questionText,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
