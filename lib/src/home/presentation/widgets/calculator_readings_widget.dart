import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/fitness_reading_item.dart';

class CalculatorReadingsWidget extends StatelessWidget {
  final VoidCallback onClick;
  final int steps;
  final double calories;
  final int? moveMin;

  const CalculatorReadingsWidget({
    super.key,
    required this.onClick,
    required this.steps,
    required this.calories,
    this.moveMin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
        child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FitnessReadingItem(
              onTap: onClick,
              lottieAsset: 'assets/home/lotties/steps.json',
              value: _formatSteps(steps),
              label: 'Steps',
            ),
            Divider(
              indent: 8.w,
              endIndent: 8.w,
              color: Colors.white,
            ),
            FitnessReadingItem(
              onTap: onClick,
              lottieAsset: 'assets/home/lotties/flame.json',
              value: calories > 0 ? calories.toStringAsFixed(0) : '0',
              label: 'Calories',
              lottieHeight: 40.h,
              lottieWidth: 40.w,
              bottomSpacing: 2.h,
            ),
            Divider(
              indent: 8.w,
              endIndent: 8.w,
              color: Colors.white,
            ),
            FitnessReadingItem(
              onTap: onClick,
              lottieAsset: 'assets/home/lotties/heart1.json',
              value: moveMin != null ? moveMin!.toString() : '0',
              label: 'Move Min',
              lottieHeight: 25.h,
              lottieWidth: 25.w,
              topSpacing: 4.h,
              bottomSpacing: 3.h,
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

