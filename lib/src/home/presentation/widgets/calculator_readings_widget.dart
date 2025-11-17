import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

/// Widget displaying calculator readings (BMI, BMR, HRC)
class CalculatorReadingsWidget extends StatelessWidget {
  final VoidCallback onClick;
  final double bmi;
  final int bmr;
  final int hrc;

  const CalculatorReadingsWidget({
    super.key,
    required this.onClick,
    required this.bmi,
    required this.bmr,
    required this.hrc,
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
                        'assets/lotties/steps.json',
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      bmi.toStringAsFixed(2),
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'BMI',
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
                      child: LottieBuilder.asset('assets/lotties/flame.json'),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      bmr.toString(),
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'BMR',
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
                      child: LottieBuilder.asset('assets/lotties/heart1.json'),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      hrc.toString(),
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'HRC',
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
}

