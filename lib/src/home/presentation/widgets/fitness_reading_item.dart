import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable widget for displaying a fitness reading item (Steps, Calories, Heart Rate)
class FitnessReadingItem extends StatelessWidget {
  final VoidCallback onTap;
  final String lottieAsset;
  final String value;
  final String label;
  final double? lottieHeight;
  final double? lottieWidth;
  final double? topSpacing;
  final double? bottomSpacing;

  const FitnessReadingItem({
    super.key,
    required this.onTap,
    required this.lottieAsset,
    required this.value,
    required this.label,
    this.lottieHeight,
    this.lottieWidth,
    this.topSpacing,
    this.bottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (topSpacing != null) SizedBox(height: topSpacing),
          SizedBox(
            height: lottieHeight ?? 35.h,
            width: lottieWidth,
            child: LottieBuilder.asset(lottieAsset),
          ),
          SizedBox(height: bottomSpacing ?? 5.h),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

