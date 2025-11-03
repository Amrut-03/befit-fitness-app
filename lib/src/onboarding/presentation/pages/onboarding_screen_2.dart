import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/routes/navigation_service.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Second onboarding screen about nutrition
class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: CustomIconButton(
          onPressed: () => context.navigateToOnboarding1(),
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
                SizedBox(height: 30.h),
                SizedBox(
                  height: 300.h,
                  width: 300.w,
                  child: LottieBuilder.asset(
                    'assets/onboarding/lotties/onboarding2.json',
                  ),
                ),
                CustomTextRich(
                  text1: '"  ',
                  textColor1: AppColors.primary,
                  fontWeight1: FontWeight.bold,
                  fontSize1: 18.sp,
                  text2:
                      'A balanced diet provides essential nutrients, maintains weight, boosts immunity, and prevents diseases. Make smart food choices to fuel your fitness journey.',
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
                      onPressed: () => context.navigateToOnboarding3(),
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
                      iconSize: 15.w,
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

