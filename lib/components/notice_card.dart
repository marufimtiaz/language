import 'package:flutter/material.dart';
// import '../pages/details_page.dart';
// import 'providers.dart';

class NoticeCard extends StatelessWidget {
  final String titleText;
  final bool isActive;
  final int completionNum;
  final bool isDone;
  final String chipText;
  final String smallText;
  final bool isStudent;
  final int totalStudents; // Add this parameter
  final VoidCallback? onPressed;

  const NoticeCard({
    super.key,
    required this.completionNum,
    required this.titleText,
    required this.isActive,
    required this.isDone,
    required this.chipText,
    required this.smallText,
    required this.isStudent,
    required this.totalStudents, // Initialize it here
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color deadlineChipColor = isActive
        ? (isStudent && !isDone ? Colors.red.shade50 : Colors.green.shade50)
        : Colors.grey.shade300;

    final Color completionChipColor = isActive
        ? (completionNum < totalStudents / 2
            ? Colors.red.shade50
            : Colors.green.shade50)
        : Colors.grey.shade300;

    final Color deadlineChipTextColor = isActive
        ? (isStudent && !isDone ? Colors.red.shade900 : Colors.green.shade900)
        : Colors.grey.shade700;

    final Color completionChipTextColor = isActive
        ? (completionNum < totalStudents / 2
            ? Colors.red.shade900
            : Colors.green.shade900)
        : Colors.grey.shade700;

    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: isActive
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleRow(
                isStudent: isStudent,
                completionChipColor: completionChipColor,
                completionChipTextColor: completionChipTextColor,
              ),
              const SizedBox(height: 12),
              _deadlineChip(
                chipText: chipText,
                chipColor: deadlineChipColor,
                textColor: deadlineChipTextColor,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  smallText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleRow({
    required bool isStudent,
    required Color completionChipColor,
    required Color completionChipTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titleText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: !isActive ? Colors.grey.shade700 : null,
            ),
          ),
        ),
        if (isStudent && isDone)
          const Icon(Icons.check_circle, color: Colors.green),
        if (!isStudent)
          _completionChip(
            chipText:
                '$completionNum/$totalStudents', // Use dynamic totalStudents here
            chipColor: completionChipColor,
            textColor: completionChipTextColor,
          ),
      ],
    );
  }

  Widget _completionChip({
    required String chipText,
    required Color chipColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Chip(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        backgroundColor: chipColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: chipColor),
        ),
        label: Text(
          chipText,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _deadlineChip({
    required String chipText,
    required Color chipColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Chip(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        backgroundColor: chipColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: chipColor),
        ),
        label: Text(
          chipText,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
