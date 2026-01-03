import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/usecase/save_user_profile_usecase.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/permissions/presentation/screens/permissions_screen.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ProfileOnboardingScreen3 extends StatefulWidget {
  static const String route = '/profile-onboarding/3';

  const ProfileOnboardingScreen3({super.key});

  @override
  State<ProfileOnboardingScreen3> createState() => _ProfileOnboardingScreen3State();
}

class _ProfileOnboardingScreen3State extends State<ProfileOnboardingScreen3> {
  bool _isSaving = false;

  Future<void> _onGetStarted(BuildContext context) async {
    // Get profile from previous screen via GoRouter
    final extra = GoRouterState.of(context).extra;
    final profile = extra is UserProfile ? extra : null;

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data is missing')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save complete profile with isProfileComplete: true
      final saveProfileUseCase = getIt<SaveUserProfileUseCase>();
      await saveProfileUseCase(profile);

      // Verify the profile was saved before navigating
      // This prevents the router redirect from sending us back to onboarding
      final profileRepository = getIt<UserProfileRepository>();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Wait and verify the data is written
        bool isComplete = false;
        int retries = 0;
        while (!isComplete && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 300));
          isComplete = await profileRepository.isProfileComplete(firebaseUser.uid);
          retries++;
        }
      }

      // Check if permissions are already granted
      final permissionService = PermissionService();
      final arePermissionsGranted = await permissionService.areAllPermissionsGranted();

      // Navigate to permissions screen if not granted, otherwise go to home
      if (mounted) {
        if (arePermissionsGranted) {
          // Permissions already granted, go to home
          context.go(HomePage.route);
        } else {
          // Navigate to permissions screen first
          context.go(PermissionsScreen.route);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Congratulation animation - full screen overlay
            Positioned.fill(
              child: LottieBuilder.asset(
                'assets/onboarding/lotties/congratulation.json',
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),
            // Content layer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome animation - centered
                  SizedBox(
                    height: 250.h,
                    width: 250.w,
                    child: LottieBuilder.asset(
                      'assets/onboarding/lotties/Welcome.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  // Welcome text
                  CustomTextRich(
                    text1: 'Welcome to ',
                    textColor1: AppColors.textPrimary,
                    fontWeight1: FontWeight.bold,
                    fontSize1: 28.sp,
                    text2: 'BeFit',
                    textColor2: AppColors.primary,
                    fontWeight2: FontWeight.bold,
                    fontSize2: 28.sp,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'You\'re all set! Let\'s start your fitness journey.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16.sp,
                      color: AppColors.textPrimary.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 60.h),
                  // Get Started button
                  ElevatedIconButton(
                    minWidth: double.infinity,
                    minHeight: 50.h,
                    elevationValue: 5.w,
                    text: 'Get Started',
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    icon: Icons.arrow_forward_ios_rounded,
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    mainAxisAlignment: MainAxisAlignment.center,
                    iconSize: 20.w,
                    width: 10.w,
                    onPressed: _isSaving ? () {} : () => _onGetStarted(context),
                    backgroundColor: AppColors.primary,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

