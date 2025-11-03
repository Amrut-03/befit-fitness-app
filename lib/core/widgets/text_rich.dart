import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable rich text widget for onboarding screens
class CustomTextRich extends StatelessWidget {
  final String text1;
  final Color textColor1;
  final FontWeight fontWeight1;
  final double fontSize1;
  final String text2;
  final Color textColor2;
  final FontWeight fontWeight2;
  final double fontSize2;
  final String? text3;
  final Color? textColor3;
  final FontWeight? fontWeight3;
  final double? fontSize3;
  final TextAlign textAlign;

  const CustomTextRich({
    super.key,
    required this.text1,
    required this.textColor1,
    required this.fontWeight1,
    required this.fontSize1,
    required this.text2,
    required this.textColor2,
    required this.fontWeight2,
    required this.fontSize2,
    this.text3,
    this.textColor3,
    this.fontWeight3,
    this.fontSize3,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textAlign: textAlign,
      TextSpan(
        text: text1,
        style: GoogleFonts.ubuntu(
          color: textColor1,
          fontWeight: fontWeight1,
          fontSize: fontSize1,
        ),
        children: [
          TextSpan(
            text: text2,
            style: GoogleFonts.ubuntu(
              color: textColor2,
              fontWeight: fontWeight2,
              fontSize: fontSize2,
            ),
          ),
          if (text3 != null)
            TextSpan(
              text: text3,
              style: GoogleFonts.ubuntu(
                color: textColor3,
                fontWeight: fontWeight3,
                fontSize: fontSize3,
              ),
            ),
        ],
      ),
    );
  }
}

