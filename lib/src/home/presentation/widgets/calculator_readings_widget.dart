import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

/// Widget displaying user fitness data (Steps, Calories, Heart Rate)
class CalculatorReadingsWidget extends StatelessWidget {
  final VoidCallback onClick;
  final int steps;
  final double calories;
  final double? heartRate;

  const CalculatorReadingsWidget({
    super.key,
    required this.onClick,
    required this.steps,
    required this.calories,
    this.heartRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      height: 250.h,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: InkWell(
                onTap: onClick,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 35.h,
                      child: LottieBuilder.asset(
                        'assets/home/lotties/steps.json',
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      _formatSteps(steps),
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Steps',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              indent: 8.w,
              endIndent: 8.w,
              color: Colors.white,
            ),
            Flexible(
              child: InkWell(
                onTap: onClick,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 40.h,
                      width: 40.w,
                      child: LottieBuilder.asset('assets/home/lotties/flame.json'),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      calories.toStringAsFixed(0),
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Calories',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              indent: 8.w,
              endIndent: 8.w,
              color: Colors.white,
            ),
            Flexible(
              child: InkWell(
                onTap: onClick,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 4.h),
                    SizedBox(
                      height: 25.h,
                      width: 25.w,
                      child: LottieBuilder.asset('assets/home/lotties/heart1.json'),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      heartRate != null ? heartRate!.toStringAsFixed(0) : '--',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Heart Rate',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format steps number for display (e.g., 1234 -> 1.2K, 1234567 -> 1.2M)
  String _formatSteps(int steps) {
    if (steps >= 1000000) {
      return '${(steps / 1000000).toStringAsFixed(1)}M';
    } else if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}K';
    } else {
      return steps.toString();
    }
  }
}

