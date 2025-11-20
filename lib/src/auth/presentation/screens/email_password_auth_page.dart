import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailPasswordAuthPage extends StatelessWidget {
  static const String route = '/email-password-auth';
  const EmailPasswordAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: const _EmailPasswordAuthPageContent(),
    );
  }
}

class _EmailPasswordAuthPageContent extends StatefulWidget {
  const _EmailPasswordAuthPageContent();

  @override
  State<_EmailPasswordAuthPageContent> createState() =>
      _EmailPasswordAuthPageContentState();
}

class _EmailPasswordAuthPageContentState
    extends State<_EmailPasswordAuthPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  bool _signInPasswordVisible = false;
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;
  bool _justSignedUp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizations.signIn_or_signUp,
          style: GoogleFonts.ubuntu(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textPrimary.withOpacity(0.6),
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.ubuntu(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontWeight: FontWeight.normal,
            fontSize: 16.sp,
          ),
          tabs: [
            Tab(text: localizations.signIn),
            Tab(text: localizations.signUp),
          ],
        ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome, ${state.user.displayName ?? state.user.email}!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is Unauthenticated && _justSignedUp) {
            // Show success message after sign-up
            _justSignedUp = false;
            // Clear sign-up form
            _signUpEmailController.clear();
            _signUpPasswordController.clear();
            _signUpConfirmPasswordController.clear();
            // Switch to sign-in tab
            _tabController.animateTo(0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account created successfully!',
                      style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'A verification email has been sent to ${_signUpEmailController.text.trim()}. Please check your inbox (and spam folder) to verify your account before signing in.',
                      style: GoogleFonts.ubuntu(fontSize: 12.sp),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return TabBarView(
            controller: _tabController,
            children: [
              // Sign-In Tab
              _buildSignInTab(context, localizations, isLoading),
              // Sign-Up Tab
              _buildSignUpTab(context, localizations, isLoading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSignInTab(
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
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab(
    BuildContext context,
    AppLocalizations localizations,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            TextFormField(
              controller: _signUpEmailController,
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
              controller: _signUpPasswordController,
              obscureText: !_signUpPasswordVisible,
              decoration: InputDecoration(
                labelText: localizations.password,
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _signUpPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _signUpPasswordVisible = !_signUpPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            TextFormField(
              controller: _signUpConfirmPasswordController,
              obscureText: !_signUpConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: localizations.confirmPassword,
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _signUpConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _signUpConfirmPasswordVisible =
                          !_signUpConfirmPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _signUpPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_signUpFormKey.currentState!.validate()) {
                        _justSignedUp = true;
                        context.read<AuthBloc>().add(
                              SignUpWithEmailPasswordEvent(
                                email: _signUpEmailController.text.trim(),
                                password: _signUpPasswordController.text,
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
                      localizations.createAccount,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                'A verification email will be sent to your email address. Please verify your email to complete the registration.',
                style: GoogleFonts.ubuntu(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
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
    // Get the AuthBloc from the parent context before showing the dialog
    final authBloc = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: authBloc,
        child: AlertDialog(
          title: Text(
            localizations.forgotPassword,
            style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.bold,
            ),
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

