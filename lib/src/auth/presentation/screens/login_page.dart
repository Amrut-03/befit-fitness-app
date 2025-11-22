import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/email_password_auth_page.dart';
import 'package:befit_fitness_app/src/onboarding/presentation/widgets/onboarding_carousel.dart';
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
              // Navigate to home screen or handle authenticated state
              // TODO: Navigate to home screen when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Welcome, ${state.user.displayName ?? state.user.email}!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
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
                        onPressed: () {
                          if (!isLoading) {
                            context.push(EmailPasswordAuthPage.route);
                          }
                        },
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
