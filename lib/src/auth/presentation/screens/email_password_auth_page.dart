import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/sign_up_page.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen1.dart';
import 'package:befit_fitness_app/src/permissions/presentation/screens/permissions_screen.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    extends State<_EmailPasswordAuthPageContent> {
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
        // Profile is complete, check permissions then go to home
        if (context.mounted) {
          // Check if permissions are already granted
          final permissionService = PermissionService();
          final permissionsGranted = await permissionService.areAllPermissionsGranted();
          
          if (permissionsGranted) {
            context.go(HomePage.route);
          } else {
            // Show permissions screen first
            context.go(PermissionsScreen.route);
          }
        }
      } else {
        // Profile not complete, get existing profile from Firestore
        UserProfile? existingProfile = await profileRepository.getUserProfile(documentId);
        
        // Get user account data for auto-filling
        final userName = firebaseUser.displayName;
        final userPhotoUrl = firebaseUser.photoURL;
        
        // Merge: Use user data for name/photo (always auto-fill)
        // Keep existing profile data for other fields (DOB, gender, workout, purpose)
        final mergedProfile = (existingProfile ?? const UserProfile()).copyWith(
          // Always use user name if available (auto-fill)
          name: (userName != null && userName.isNotEmpty) 
              ? userName 
              : existingProfile?.name,
          // Always use user photo if available (auto-fill)
          photoUrl: (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
              ? userPhotoUrl
              : existingProfile?.photoUrl,
        );

        // Navigate to profile onboarding with merged profile data
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
            _handleAuthenticatedUser(context, state.user);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return _buildSignInForm(context, localizations, isLoading);
        },
      ),
    );
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
                onPressed: () =>
                    _showForgotPasswordDialog(context, localizations),
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
                    context.push(SignUpPage.route);
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
    // Get the AuthBloc from the parent context before showing the dialog
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
                      content: Text(
                        'Password reset email sent! Please check your inbox.',
                      ),
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
