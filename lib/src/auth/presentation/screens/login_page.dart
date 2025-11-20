import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_screen.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/widgets/onboarding_carousel.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  static const String route = '/login';
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>()..add(const CheckAuthStateEvent()),
      child: const _LoginPageContent(),
    );
  }
}

class _LoginPageContent extends StatelessWidget {
  const _LoginPageContent();

  Future<void> _handleAuthenticatedUser(BuildContext context, user) async {
    try {
      final profileRepository = getIt<UserProfileRepository>();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser == null) return;

      // Update auth user info (email and photoUrl) in Firestore
      final documentId = (firebaseUser.email ?? firebaseUser.uid).toLowerCase();

      await profileRepository.updateAuthUserInfo(
        documentId: documentId,
        userId: firebaseUser.uid,
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
      );

      // Check if profile is complete
      final isComplete = await profileRepository.isProfileComplete(documentId);
      
      if (isComplete) {
        // Profile is complete, go to home
        if (context.mounted) {
          context.go(HomeScreen.route);
        }
      } else {
        // Profile not complete, get existing profile from Firestore
        UserProfile? existingProfile = await profileRepository.getUserProfile(documentId);
        
        // Get Google account data for auto-filling
        final googleName = firebaseUser.displayName;
        final googlePhotoUrl = firebaseUser.photoURL;
        
        // Merge: Use Google data for name/photo (always auto-fill from Google)
        // Keep existing profile data for other fields (DOB, gender, workout, purpose)
        final mergedProfile = (existingProfile ?? const UserProfile()).copyWith(
          // Always use Google name if available (auto-fill)
          name: (googleName != null && googleName.isNotEmpty) 
              ? googleName 
              : existingProfile?.name,
          // Always use Google photo if available (auto-fill)
          photoUrl: (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty)
              ? googlePhotoUrl
              : existingProfile?.photoUrl,
        );

        // Navigate to profile onboarding with merged profile data (Google + existing)
        if (context.mounted) {
          context.go(
            ProfileOnboardingScreen1.route,
            extra: mergedProfile,
          );
        }
      }
    } catch (e) {
      // On error, still navigate to onboarding
      if (context.mounted) {
        context.go(ProfileOnboardingScreen1.route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is Authenticated) {
              _handleAuthenticatedUser(context, state.user);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Column(
              children: [
                // App name at top
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: CustomTextRich(
                    text1: localizations.appNameBe,
                    textColor1: AppColors.textPrimary,
                    fontWeight1: FontWeight.bold,
                    fontSize1: 25.sp,
                    text2: localizations.appNameFit,
                    textColor2: AppColors.primary,
                    fontWeight2: FontWeight.bold,
                    fontSize2: 25.sp,
                  ),
                ),
                // Onboarding carousel - takes most of the screen
                Expanded(child: const OnboardingCarousel()),
                // Buttons at bottom
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    children: [
                      // Sign In Button
                      ElevatedIconButton(
                        minWidth: double.infinity,
                        minHeight: 50.h,
                        elevationValue: 5.w,
                        text: 'Sign in with',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        icon: Icons.email_outlined,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        mainAxisAlignment: MainAxisAlignment.center,
                        iconSize: 20.w,
                        width: 10.w,
                        onPressed: () {},
                        backgroundColor: Colors.black,
                        isLoading: isLoading,
                      ),
                      SizedBox(height: 15.h),
                      // Google Sign In Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50.h),
                          backgroundColor: Colors.black,
                          elevation: 5.w,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  const SignInWithGoogleEvent(),
                                );
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoading)
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else ...[
                              Text(
                                localizations.signInWith,
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Image.asset(
                                'assets/onboarding/icons/google.png',
                                width: 24.w,
                                height: 24.w,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
