import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/widgets/onboarding_carousel.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';
import 'package:befit_fitness_app/src/permissions/presentation/screens/permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  static const String route = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isGoogleSignInLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                setState(() {
                  _isGoogleSignInLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is AuthLoading) {
                setState(() {
                  _isGoogleSignInLoading = true;
                });
              } else if (state is Authenticated) {
                setState(() {
                  _isGoogleSignInLoading = false;
                });
                _handleNavigation(context, state);
              } else if (state is Unauthenticated) {
                setState(() {
                  _isGoogleSignInLoading = false;
                });
              }
            },
            builder: (context, state) {
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
                        // Google Sign In Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50.h),
                            backgroundColor: Colors.black,
                            elevation: 5.w,
                          ),
                          onPressed: _isGoogleSignInLoading
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
                              if (_isGoogleSignInLoading)
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
      ),
    );
  }

  void _handleNavigation(BuildContext context, Authenticated state) async {
    if (!context.mounted) return;

    if (state.isProfileComplete == true) {
      // Profile is complete, check permissions
      final permissionService = PermissionService();
      final arePermissionsGranted = await permissionService.areAllPermissionsGranted();
      
      if (!context.mounted) return;
      
      if (arePermissionsGranted) {
        // Permissions already granted, go to home
        context.go(HomePage.route);
      } else {
        // Show permission screen with skip option
        _showPermissionDialog(context);
      }
    } else {
      context.go(
        ProfileOnboardingScreen1.route,
        extra: state.mergedProfile,
      );
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Connect with Google Fit',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        content: Text(
          'To track your fitness data and health metrics, we need to connect with Google Fit.\n\n'
          'You can connect now or do it later from the home screen.',
          style: GoogleFonts.ubuntu(
            fontSize: 16.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Skip and go to home
              context.go(HomePage.route);
            },
            child: Text(
              'Do it Later',
              style: GoogleFonts.ubuntu(
                color: Colors.grey[600],
                fontSize: 16.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Navigate to permissions screen
              context.push(PermissionsScreen.route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Connect Now',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
