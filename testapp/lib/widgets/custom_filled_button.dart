import 'package:flutter/material.dart';

class CustomFilledButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback? onPressed;
  final Widget? destination;
  final FontWeight? fontWeight;
  final double? fontSize;

  const CustomFilledButton({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.onPressed,
    this.destination,
    this.fontWeight,
    this.fontSize,
  });

  @override
  State<CustomFilledButton> createState() => _CustomFilledButtonState();
}

class _CustomFilledButtonState extends State<CustomFilledButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed:
            widget.onPressed ??
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.destination ?? widget),
            ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.textColor,
            fontSize: widget.fontSize ?? 16,
            fontWeight: widget.fontWeight ?? FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
