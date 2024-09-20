import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;
  final void Function()? onPressed;
  final bool? isLoading;

  const CustomButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isLoading == true ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.textColor,
        side: widget.borderColor != null
            ? BorderSide(color: widget.borderColor!)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: widget.isLoading == true
          ? const CircularProgressIndicator()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) Icon(widget.icon),
                if (widget.icon != null) const SizedBox(width: 10),
                Text(widget.label),
              ],
            ),
    );
  }
}
