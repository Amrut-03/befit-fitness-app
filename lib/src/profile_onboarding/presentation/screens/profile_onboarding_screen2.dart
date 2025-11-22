import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileOnboardingScreen2 extends StatefulWidget {
  static const String route = '/profile-onboarding/2';

  const ProfileOnboardingScreen2({super.key});

  @override
  State<ProfileOnboardingScreen2> createState() =>
      _ProfileOnboardingScreen2State();
}

class _ProfileOnboardingScreen2State extends State<ProfileOnboardingScreen2> {
  String? _selectedWorkoutType;
  String? _selectedPurpose;
  UserProfile? _profile;

  final List<String> _workoutTypes = [
    'Cardio',
    'Strength Training',
    'Yoga',
    'Pilates',
    'HIIT',
    'CrossFit',
    'Swimming',
    'Running',
    'Cycling',
    'Dancing',
  ];

  final List<String> _purposes = [
    'Weight Loss',
    'Muscle Gain',
    'General Fitness',
    'Endurance',
    'Flexibility',
    'Rehabilitation',
    'Athletic Performance',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get profile from previous screen via GoRouter
    final extra = GoRouterState.of(context).extra;
    if (extra is UserProfile && _profile == null) {
      setState(() {
        _profile = extra;
        _selectedWorkoutType = extra.workoutType;
        _selectedPurpose = extra.purpose;
      });
    }
  }

  bool get _isValid => _selectedWorkoutType != null && _selectedPurpose != null;

  void _onNext() {
    if (!_isValid) return;

    final profile = (_profile ?? const UserProfile()).copyWith(
      workoutType: _selectedWorkoutType,
      purpose: _selectedPurpose,
    );

    context.push(ProfileOnboardingScreen3.route, extra: profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20.w,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'What\'s your fitness goal?',
                style: GoogleFonts.ubuntu(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Choose your preferred workout type and fitness purpose',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 40.h),
              // Workout Type
              Text(
                'Workout Type',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 15.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _workoutTypes.map((type) {
                  final isSelected = _selectedWorkoutType == type;
                  return InkWell(
                    onTap: () => setState(() => _selectedWorkoutType = type),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14.sp,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 40.h),
              // Purpose
              Text(
                'Fitness Purpose',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 15.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _purposes.map((purpose) {
                  final isSelected = _selectedPurpose == purpose;
                  return InkWell(
                    onTap: () => setState(() => _selectedPurpose = purpose),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: Text(
                        purpose,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14.sp,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 40.h),
              // Next button
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: ElevatedIconButton(
                  minWidth: double.infinity,
                  minHeight: 50.h,
                  elevationValue: 5.w,
                  text: 'Next',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  icon: Icons.arrow_forward_ios_rounded,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  mainAxisAlignment: MainAxisAlignment.center,
                  iconSize: 20.w,
                  width: 10.w,
                  onPressed: () {
                    if (!_isValid) return;
                    _onNext();
                  },
                  backgroundColor: _isValid ? AppColors.primary : Colors.grey,
                  isLoading: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
