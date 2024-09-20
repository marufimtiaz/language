import 'package:flutter/material.dart';

String? studentLabel;

class ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.12,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Icon(
                  icon,
                  color: color,
                  size: 30, // Adjusted size
                ),
              ),
              const SizedBox(height: 4), // Reduced spacing
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16, // Adjusted size
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis, // Handle overflow
                  softWrap: true, // Allow text to wrap
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
