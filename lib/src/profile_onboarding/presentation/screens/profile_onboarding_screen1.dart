import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/widgets.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/profile_onboarding/presentation/screens/profile_onboarding_screen2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileOnboardingScreen1 extends StatefulWidget {
  static const String route = '/profile-onboarding/1';
  final UserProfile? initialProfile;

  const ProfileOnboardingScreen1({
    super.key,
    this.initialProfile,
  });

  @override
  State<ProfileOnboardingScreen1> createState() => _ProfileOnboardingScreen1State();
}

class _ProfileOnboardingScreen1State extends State<ProfileOnboardingScreen1> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _nameController.text = widget.initialProfile!.name ?? '';
      _selectedDate = widget.initialProfile!.dateOfBirth;
      _selectedGender = widget.initialProfile!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool get _isValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedGender != null;
  }

  void _onNext() {
    if (!_isValid) return;

    final profile = UserProfile(
      name: _nameController.text.trim(),
      dateOfBirth: _selectedDate,
      gender: _selectedGender,
    );

    context.push(
      ProfileOnboardingScreen2.route,
      extra: profile,
    );
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
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.w),
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
              // Profile preview section (if data exists)
              if (widget.initialProfile?.photoUrl != null ||
                  widget.initialProfile?.name != null)
                Column(
                  children: [
                    if (widget.initialProfile?.photoUrl != null)
                      CircleAvatar(
                        radius: 50.r,
                        backgroundImage: CachedNetworkImageProvider(
                          widget.initialProfile!.photoUrl!,
                        ),
                      ),
                    if (widget.initialProfile?.photoUrl != null)
                      SizedBox(height: 10.h),
                    if (widget.initialProfile?.name != null)
                      Text(
                        'Welcome, ${widget.initialProfile!.name}!',
                        style: GoogleFonts.ubuntu(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    if (widget.initialProfile?.name != null)
                      SizedBox(height: 20.h),
                  ],
                ),
              Text(
                'Tell us about yourself',
                style: GoogleFonts.ubuntu(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'We\'ll use this information to personalize your experience',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 40.h),
              // Name field
              Text(
                'Full Name',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.ubuntu(
                    color: AppColors.textPrimary.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.textPrimary.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.textPrimary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                style: GoogleFonts.ubuntu(fontSize: 16.sp),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 30.h),
              // Date of Birth
              Text(
                'Date of Birth',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textPrimary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20.w,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select your date of birth',
                        style: GoogleFonts.ubuntu(
                          fontSize: 16.sp,
                          color: _selectedDate != null
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.w,
                        color: AppColors.textPrimary.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              // Gender selection
              Text(
                'Gender',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption('male', 'Male'),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: _buildGenderOption('female', 'Female'),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: _buildGenderOption('other', 'Other'),
                  ),
                ],
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

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 16.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

