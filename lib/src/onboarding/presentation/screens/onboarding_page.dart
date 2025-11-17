import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/routes/navigation_service.dart';
import 'package:befit_fitness_app/core/services/app_initialization_service.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/onboarding/domain/models/onboarding_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class OnboardingPage extends StatelessWidget {
  static const String onboarding = '/onboarding/:page';
  static const String onboarding1 = '/onboarding/1';
  static const String onboarding2 = '/onboarding/2';
  static const String onboarding3 = '/onboarding/3';
  static const String onboarding4 = '/onboarding/4';
  
  final int pageIndex;

  const OnboardingPage({
    super.key,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Validate page index - if invalid, return error widget instead of throwing
    if (pageIndex < 0 || pageIndex >= OnboardingContentRepository.totalPages) {
      // Return error widget and redirect to login using GoRouter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(LoginPage.route);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final content = OnboardingContentRepository.getPage(context, pageIndex);
    final isFirstPage = pageIndex == 0;
    final isLastPage = pageIndex == OnboardingContentRepository.totalPages - 1;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: isFirstPage
            ? null
            : CustomIconButton(
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_ios_new_rounded,
                iconColor: AppColors.textPrimary,
                iconSize: 20.w,
              ),
        actions: [
          if (!isLastPage)
            CustomTextButton(
              text: localizations.skip,
              onPressed: () async {
                // Mark onboarding as completed when skipped
                await AppInitializationService.setOnboardingCompleted();
                context.navigateToLogin();
              },
              textColor: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 18.sp,
              icon: Icons.arrow_forward_ios_rounded,
              iconSize: 15.sp,
              iconColor: AppColors.textPrimary,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          if (!isLastPage) SizedBox(width: 20.w),
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
                  text1: localizations.appNameBe,
                  textColor1: AppColors.textPrimary,
                  fontWeight1: FontWeight.bold,
                  fontSize1: 25.sp,
                  text2: localizations.appNameFit,
                  textColor2: AppColors.primary,
                  fontWeight2: FontWeight.bold,
                  fontSize2: 25.sp,
                ),
                SizedBox(height: pageIndex == 1 ? 30.h : 20.h),
                SizedBox(
                  height: 300.h,
                  width: 300.w,
                  child: LottieBuilder.asset(
                    content.lottieAssetPath,
                  ),
                ),
                SizedBox(height: pageIndex == 1 ? 0 : 20.h),
                CustomTextRich(
                  text1: '"  ',
                  textColor1: AppColors.primary,
                  fontWeight1: FontWeight.bold,
                  fontSize1: 18.sp,
                  text2: content.getDescription(context),
                  textColor2: AppColors.textPrimary,
                  fontWeight2: FontWeight.bold,
                  fontSize2: 18.sp,
                  text3: '  "',
                  textColor3: AppColors.primary,
                  fontWeight3: FontWeight.bold,
                  fontSize3: 18.sp,
                ),
                SizedBox(height: pageIndex == 1 ? 10.h : 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedIconButton(
                      onPressed: () async {
                        if (isLastPage) {
                          // Mark onboarding as completed
                          await AppInitializationService.setOnboardingCompleted();
                          context.navigateToLogin();
                        } else {
                          // Navigate to next page
                          context.navigateToOnboardingPage(pageIndex + 1);
                        }
                      },
                      minWidth: 100.w,
                      minHeight: 35.h,
                      backgroundColor: AppColors.primary,
                      elevationValue: 5.w,
                      mainAxisAlignment: MainAxisAlignment.center,
                      text: isLastPage ? localizations.getStarted : localizations.next,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      textColor: AppColors.textPrimary,
                      icon: Icons.arrow_forward_ios_rounded,
                      iconColor: AppColors.textPrimary,
                      iconSize: isLastPage ? 15.sp : 15.w,
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

