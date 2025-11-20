import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  static const String route = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: CustomTextRich(
          text1: localizations.appNameBe,
          textColor1: AppColors.textPrimary,
          fontWeight1: FontWeight.bold,
          fontSize1: 20.sp,
          text2: localizations.appNameFit,
          textColor2: AppColors.primary,
          fontWeight2: FontWeight.bold,
          fontSize2: 20.sp,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 100.w,
              color: AppColors.primary,
            ),
            SizedBox(height: 20.h),
            Text(
              'Welcome to Home!',
              style: GoogleFonts.ubuntu(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Your profile onboarding is complete.',
              style: GoogleFonts.ubuntu(
                fontSize: 16.sp,
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

