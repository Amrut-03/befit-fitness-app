import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable text button with an icon
class CustomTextButton extends StatelessWidget {
  final Color textColor;
  final String text;
  final FontWeight fontWeight;
  final double fontSize;
  final IconData? icon;
  final MainAxisAlignment mainAxisAlignment;
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback onPressed;

  const CustomTextButton({
    super.key,
    required this.textColor,
    required this.text,
    required this.fontWeight,
    required this.fontSize,
    this.icon,
    required this.mainAxisAlignment,
    this.iconColor,
    this.iconSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Text(
            text,
            style: GoogleFonts.ubuntu(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
          ),
          if (icon != null)
            Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
        ],
      ),
    );
  }
}

