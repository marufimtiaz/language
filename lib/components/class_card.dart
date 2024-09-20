import 'dart:math';

import 'package:flutter/material.dart';

class ClassCard extends StatefulWidget {
  final String titleText;
  final String leftSubText;
  final String rightSubText;
  // final MaterialColor baseColor;
  final VoidCallback onPressed;

  const ClassCard({
    super.key,
    required this.titleText,
    required this.leftSubText,
    this.rightSubText = '',
    // required this.baseColor,
    required this.onPressed,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  @override
  Widget build(BuildContext context) {
    final random = Random();
    const colors = Colors.primaries;
    final baseColor = colors[random.nextInt(colors.length)];
    final backgroundColor = baseColor.shade50;
    final titleColor = baseColor.shade800;

    return FilledButton.tonal(
      onPressed: widget.onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.titleText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.leftSubText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      widget.rightSubText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget classCard(
  BuildContext context, {
  required String titleText,
  required String leftSubText,
  required String rightSubText,
  required MaterialColor baseColor,
  required VoidCallback onPressed,
}) {
  final backgroundColor = baseColor.shade50;
  final titleColor = baseColor.shade800;

  return FilledButton.tonal(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: backgroundColor, // Set the background color
      padding: EdgeInsets.zero, // Remove default padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    leftSubText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    rightSubText,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
