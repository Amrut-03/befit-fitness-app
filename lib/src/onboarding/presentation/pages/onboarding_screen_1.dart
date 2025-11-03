import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/routes/navigation_service.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

/// First onboarding screen introducing the app
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          CustomTextButton(
            text: 'Skip',
            onPressed: () => context.navigateToOnboarding4(),
            textColor: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 18.sp,
            icon: Icons.arrow_forward_ios_rounded,
            iconSize: 15.sp,
            iconColor: AppColors.textPrimary,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextRich(
                  text1: 'Be',
                  textColor1: AppColors.textPrimary,
                  fontWeight1: FontWeight.bold,
                  fontSize1: 25.sp,
                  text2: 'Fit',
                  textColor2: AppColors.primary,
                  fontWeight2: FontWeight.bold,
                  fontSize2: 25.sp,
                ),
                SizedBox(height: 30.h),
                SizedBox(
                  height: 300.h,
                  width: 300.w,
                  child: LottieBuilder.asset(
                    'assets/onboarding/lotties/onboarding1.json',
                  ),
                ),
                SizedBox(height: 20.h),
                CustomTextRich(
                  text1: '"  ',
                  textColor1: AppColors.primary,
                  fontWeight1: FontWeight.bold,
                  fontSize1: 18.sp,
                  text2:
                      'Welcome to better health! Physical and mental  well-being help you live energetically and reduce disease risk.',
                  textColor2: AppColors.textPrimary,
                  fontWeight2: FontWeight.bold,
                  fontSize2: 18.sp,
                  text3: '  "',
                  textColor3: AppColors.primary,
                  fontWeight3: FontWeight.bold,
                  fontSize3: 18.sp,
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedIconButton(
                      onPressed: () => context.navigateToOnboarding2(),
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

