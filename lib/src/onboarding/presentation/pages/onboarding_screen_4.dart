import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/routes/navigation_service.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Fourth onboarding screen - welcome screen with login/register options
/// Note: Auth screens will be implemented in the auth feature
class OnboardingScreen4 extends StatefulWidget {
  const OnboardingScreen4({super.key});

  @override
  State<OnboardingScreen4> createState() => _OnboardingScreen4State();
}

class _OnboardingScreen4State extends State<OnboardingScreen4> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
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
              SizedBox(
                height: 300.h,
                width: 300.w,
                child: LottieBuilder.asset(
                  'assets/onboarding/lotties/onboarding4.json',
                ),
              ),
              Text(
                'Hello, WelCome!',
                style: GoogleFonts.ubuntu(
                  fontSize: 27.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Welcome to BeFit Top PlatForm to Every people',
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
                  text: 'Login',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  icon: Icons.email_outlined,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  mainAxisAlignment: MainAxisAlignment.center,
                  iconSize: 20.w,
                  width: 10.w,
                  onPressed: () {
                    // TODO: Navigate to login screen when auth feature is implemented
                    // NavigationUtils.push(
                    //   context,
                    //   const SignInScreen(),
                    //   transitionType: PageTransitionType.bottomToTop,
                    //   durationMs: 200,
                    // );
                  },
                  backgroundColor: Colors.black,
                  isLoading: _isLoading,
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: ElevatedIconButton(
                  minWidth: 300.w,
                  minHeight: 40.h,
                  elevationValue: 5.w,
                  text: 'Register',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  icon: Icons.list_alt_outlined,
                  backgroundColor: Colors.black,
                  mainAxisAlignment: MainAxisAlignment.center,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  iconSize: 20.w,
                  width: 10.w,
                  onPressed: () {
                    // TODO: Navigate to register screen when auth feature is implemented
                    // NavigationUtils.push(
                    //   context,
                    //   const SignUpScreen(),
                    //   transitionType: PageTransitionType.bottomToTop,
                    //   durationMs: 200,
                    // );
                  },
                  isLoading: _isLoading,
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
                  onPressed: () async {
                    // TODO: Implement Google Sign-In when auth feature is ready
                    // try {
                    //   setState(() => _isLoading = true);
                    //   final user = await authService.signInWithGoogle(context);
                    //   setState(() => _isLoading = false);
                    //
                    //   if (user != null) {
                    //     NavigationUtils.pushAndRemoveUntil(
                    //       context,
                    //       const HomeScreen(),
                    //       transitionType: PageTransitionType.rightToLeftWithFade,
                    //       durationMs: 200,
                    //     );
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(content: Text("You are signed in successfully")),
                    //     );
                    //   } else {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(content: Text("Your Sign-In failed. Please try again.")),
                    //     );
                    //   }
                    // } catch (e) {
                    //   setState(() => _isLoading = false);
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(content: Text("An error occurred: ${e.toString()}")),
                    //   );
                    // }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign in with ',
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

