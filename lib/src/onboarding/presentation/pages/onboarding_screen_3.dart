import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/routes/navigation_service.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Third onboarding screen about exercise
class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: CustomIconButton(
          onPressed: () => context.navigateToOnboarding2(),
          icon: Icons.arrow_back_ios_new_rounded,
          iconColor: AppColors.textPrimary,
          iconSize: 20.w,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Be',
                    style: GoogleFonts.ubuntu(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 25.sp,
                    ),
                    children: [
                      TextSpan(
                        text: 'Fit',
                        style: GoogleFonts.ubuntu(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 300.h,
                  width: 300.w,
                  child: LottieBuilder.asset(
                    'assets/onboarding/lotties/onboarding3.json',
                  ),
                ),
                SizedBox(height: 20.h),
                CustomTextRich(
                  text1: '"  ',
                  textColor1: AppColors.primary,
                  fontWeight1: FontWeight.bold,
                  fontSize1: 18.sp,
                  text2:
                      'Regular exercise is vital for health, managing weight, strengthening muscles and bones, improving heart health, and boosting mental well-being.',
                  textColor2: AppColors.textPrimary,
                  fontWeight2: FontWeight.bold,
                  fontSize2: 18.sp,
                  text3: '  "',
                  textColor3: AppColors.primary,
                  fontWeight3: FontWeight.bold,
                  fontSize3: 18.sp,
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedIconButton(
                      onPressed: () => context.navigateToOnboarding4(),
                      minWidth: 100.w,
                      minHeight: 35.h,
                      backgroundColor: AppColors.primary,
                      elevationValue: 5.w,
                      mainAxisAlignment: MainAxisAlignment.center,
                      text: 'next',
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      textColor: AppColors.textPrimary,
                      icon: Icons.arrow_forward_ios_rounded,
                      iconColor: AppColors.textPrimary,
                      iconSize: 15.sp,
                      width: 0.w,
                      isLoading: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

