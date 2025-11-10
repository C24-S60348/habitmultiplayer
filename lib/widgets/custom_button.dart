import 'package:flutter/material.dart';

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.fontSize = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        shadowColor: Colors.black.withOpacity(0.5),
        elevation: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

