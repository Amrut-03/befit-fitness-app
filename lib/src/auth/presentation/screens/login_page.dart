import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

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

class _LoginPageContent extends StatefulWidget {
  const _LoginPageContent();

  @override
  State<_LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<_LoginPageContent> {
  bool _isGoogleSignInLoading = false;
  bool _isEmailSignInLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthLoading) {
              // Don't update loading state here, let the button handlers manage it
            } else if (state is AuthError) {
              // Reset loading states on error
              setState(() {
                _isGoogleSignInLoading = false;
                _isEmailSignInLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is Authenticated) {
              // Reset loading states on success
              setState(() {
                _isGoogleSignInLoading = false;
                _isEmailSignInLoading = false;
              });
              // Navigate to home screen after successful authentication
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome, ${state.user.displayName ?? state.user.email}!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate to home screen
              context.go(HomePage.route);
            } else if (state is Unauthenticated) {
              // Reset loading states when unauthenticated
              setState(() {
                _isGoogleSignInLoading = false;
                _isEmailSignInLoading = false;
              });
            }
          },
          builder: (context, state) {

            return Center(
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
                  SizedBox(
                    height: 300.h,
                    width: 300.w,
                    child: LottieBuilder.asset(
                      'assets/onboarding/lotties/onboarding4.json',
                    ),
                  ),
                  Text(
                    localizations.helloWelcome,
                    style: GoogleFonts.ubuntu(
                      fontSize: 27.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      localizations.welcomeToBefit,
                      style: GoogleFonts.ubuntu(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ElevatedIconButton(
                      minWidth: 300.w,
                      minHeight: 40.h,
                      elevationValue: 5.w,
                      text: localizations.signIn,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      icon: Icons.email_outlined,
                      textColor: Colors.white,
                      iconColor: Colors.white,
                      mainAxisAlignment: MainAxisAlignment.center,
                      iconSize: 20.w,
                      width: 10.w,
                      onPressed: () {
                        if (!_isEmailSignInLoading && !_isGoogleSignInLoading) {
                          context.push('/sign-in');
                        }
                      },
                      backgroundColor: Colors.black,
                      isLoading: _isEmailSignInLoading,
                    ),
                  ),
                  Divider(
                    height: 30.h,
                    indent: 20.w,
                    endIndent: 20.w,
                    thickness: 1.w,
                    color: AppColors.textPrimary.withOpacity(0.2),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(300.w, 40.h),
                        backgroundColor: Colors.black,
                        elevation: 5.w,
                      ),
                      onPressed: (_isGoogleSignInLoading || _isEmailSignInLoading)
                          ? null
                          : () {
                              setState(() {
                                _isGoogleSignInLoading = true;
                              });
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
