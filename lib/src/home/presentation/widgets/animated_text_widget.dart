import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

/// Animated text widget for home screen
class AnimatedTextWidget extends StatelessWidget {
  const AnimatedTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 10.w),
      child: Row(
        children: [
          Text(
            'Find Your',
            style: GoogleFonts.ubuntu(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 25.sp,
            ),
          ),
          SizedBox(width: 5.w),
          AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'Workouts...',
                speed: const Duration(milliseconds: 200),
                textStyle: GoogleFonts.ubuntu(
                  color: AppColors.primaryDark,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TyperAnimatedText(
                'Nutrition...',
                speed: const Duration(milliseconds: 200),
                textStyle: GoogleFonts.ubuntu(
                  color: AppColors.primaryDark,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TyperAnimatedText(
                'Calculators...',
                speed: const Duration(milliseconds: 200),
                textStyle: GoogleFonts.ubuntu(
                  color: AppColors.primaryDark,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TyperAnimatedText(
                'Yoga\'s...',
                speed: const Duration(milliseconds: 200),
                textStyle: GoogleFonts.ubuntu(
                  color: AppColors.primaryDark,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            isRepeatingAnimation: true,
            repeatForever: true,
          ),
        ],
      ),
    );
  }
}

