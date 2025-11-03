import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable elevated button with an icon
class ElevatedIconButton extends StatelessWidget {
  final double minWidth;
  final double minHeight;
  final double width;
  final Color backgroundColor;
  final Color textColor;
  final double elevationValue;
  final String text;
  final FontWeight fontWeight;
  final double fontSize;
  final IconData icon;
  final MainAxisAlignment mainAxisAlignment;
  final Color iconColor;
  final double iconSize;
  final VoidCallback onPressed;
  final bool isLoading;

  const ElevatedIconButton({
    super.key,
    required this.minWidth,
    required this.minHeight,
    required this.elevationValue,
    required this.text,
    required this.fontWeight,
    required this.fontSize,
    required this.icon,
    required this.backgroundColor,
    required this.mainAxisAlignment,
    required this.textColor,
    required this.iconColor,
    required this.iconSize,
    required this.onPressed,
    required this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: minHeight,
        width: minWidth,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 3),
              blurRadius: 3,
              color: Colors.black.withOpacity(0.4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(minWidth, minHeight),
        backgroundColor: backgroundColor,
        elevation: elevationValue,
      ),
      onPressed: onPressed,
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
          SizedBox(width: width),
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

