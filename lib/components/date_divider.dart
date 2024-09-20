import 'package:flutter/material.dart';

class DividerRow extends StatelessWidget {
  final String noticeDate;
  const DividerRow({super.key, required this.noticeDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              noticeDate,
              style: const TextStyle(
                // fontWeight: FontWeight.bold,
                fontSize: 14,
                // color: Theme.of(context).colorScheme.onSurface, // Use color from theme
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
