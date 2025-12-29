import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInPage extends StatefulWidget {
  static const String route = '/sign-in';
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _signInPasswordVisible = false;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            localizations.signIn,
            style: GoogleFonts.ubuntu(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is Authenticated) {
              _handleNavigation(context, state);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return _buildSignInForm(context, localizations, isLoading);
          },
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, Authenticated state) {
    if (!context.mounted) return;

    if (state.isProfileComplete == true) {
      context.go(HomePage.route);
    } else {
      context.go(
        ProfileOnboardingScreen1.route,
        extra: state.mergedProfile,
      );
    }
  }

  Widget _buildSignInForm(
    BuildContext context,
    AppLocalizations localizations,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            TextFormField(
              controller: _signInEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: localizations.email,
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            TextFormField(
              controller: _signInPasswordController,
              obscureText: !_signInPasswordVisible,
              decoration: InputDecoration(
                labelText: localizations.password,
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _signInPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _signInPasswordVisible = !_signInPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordDialog(context, localizations),
                child: Text(
                  localizations.forgotPassword,
                  style: GoogleFonts.ubuntu(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_signInFormKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                              SignInWithEmailPasswordEvent(
                                email: _signInEmailController.text.trim(),
                                password: _signInPasswordController.text,
                              ),
                            );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      localizations.signIn,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.dontHaveAccount,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 5.w),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to sign up
                  },
                  child: Text(
                    localizations.signUp,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final authBloc = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: authBloc,
        child: AlertDialog(
          title: Text(
            localizations.forgotPassword,
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: localizations.email,
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.cancel),
            ),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (listenerContext, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(listenerContext).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is Unauthenticated) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(listenerContext).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent! Please check your inbox.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (builderContext, state) {
                final isLoading = state is AuthLoading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            builderContext.read<AuthBloc>().add(
                                  ResetPasswordEvent(
                                    email: emailController.text.trim(),
                                  ),
                                );
                          }
                        },
                  child: isLoading
                      ? SizedBox(
                          height: 16.h,
                          width: 16.w,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.ok),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
