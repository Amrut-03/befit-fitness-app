import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/widgets/shimmer_widget.dart';
import 'package:befit_fitness_app/core/utils/app_snackbar.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';
import 'package:befit_fitness_app/src/home/data/services/goal_service.dart';
import 'package:befit_fitness_app/src/home/data/services/enhanced_goal_service.dart';
import 'package:befit_fitness_app/src/home/data/services/macro_calculation_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profile page – edit user info saved during onboarding (Firebase CRUD).
class ProfilePage extends StatefulWidget {
  static const String route = '/profile';

  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedWorkoutType;
  String? _selectedPurpose;

  static const List<String> _workoutTypes = [
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

  static const List<String> _purposes = [
    'Weight Loss',
    'Muscle Gain',
    'General Fitness',
    'Endurance',
    'Flexibility',
    'Rehabilitation',
    'Athletic Performance',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
      }
      return;
    }

    try {
      final repo = getIt<UserProfileRepository>();
      final profile = await repo.getUserProfile(user.uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile != null) {
          _nameController.text = profile.name ?? '';
          _selectedDate = profile.dateOfBirth;
          _selectedGender = profile.gender;
          _selectedWorkoutType = profile.workoutType;
          _selectedPurpose = profile.purpose;
          if (profile.height != null) {
            _heightController.text = profile.height!.toStringAsFixed(1);
          }
          if (profile.weight != null) {
            _weightController.text = profile.weight!.toStringAsFixed(1);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Failed to load profile: ${e.toString()}');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.background,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  bool get _isValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedGender != null &&
        _selectedWorkoutType != null &&
        _selectedPurpose != null &&
        _heightController.text.trim().isNotEmpty &&
        _weightController.text.trim().isNotEmpty;
  }

  static const double _minHeightCm = 100;
  static const double _maxHeightCm = 250;
  static const double _minWeightKg = 30;
  static const double _maxWeightKg = 300;
  static const int _minAge = 13;
  static const int _maxAge = 120;

  Future<void> _saveProfile() async {
    if (!_isValid) {
      AppSnackBar.showError(context, 'Please fill all fields');
      return;
    }

    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      AppSnackBar.showError(context, 'Please enter valid height and weight');
      return;
    }
    if (height < _minHeightCm || height > _maxHeightCm) {
      AppSnackBar.showError(context, 'Height must be between $_minHeightCm and $_maxHeightCm cm');
      return;
    }
    if (weight < _minWeightKg || weight > _maxWeightKg) {
      AppSnackBar.showError(context, 'Weight must be between $_minWeightKg and $_maxWeightKg kg');
      return;
    }
    if (_selectedDate != null) {
      final now = DateTime.now();
      int age = now.year - _selectedDate!.year;
      if (now.month < _selectedDate!.month || (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
        age--;
      }
      if (age < _minAge || age > _maxAge) {
        AppSnackBar.showError(context, 'Age must be between $_minAge and $_maxAge years');
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = UserProfile(
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDate,
        gender: _selectedGender,
        workoutType: _selectedWorkoutType,
        purpose: _selectedPurpose,
        photoUrl: _profile?.photoUrl,
        height: height,
        weight: weight,
        isProfileComplete: true,
      );
      final repo = getIt<UserProfileRepository>();
      await repo.saveUserProfile(userId: user.uid, profile: updated);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isSaving = false;
      });
      AppSnackBar.showSuccess(context, 'Profile updated');
      await _recalculateGoalsAndMacros(updated);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, 'Failed to save: ${e.toString()}');
      }
    }
  }

  /// Recalculate daily goal and macros when profile (height, weight, age, gender, fitness goal, activity) changes.
  Future<void> _recalculateGoalsAndMacros(UserProfile profile) async {
    try {
      if (profile.dateOfBirth == null || profile.gender == null || profile.height == null || profile.weight == null) return;
      final now = DateTime.now();
      final dob = profile.dateOfBirth!;
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
      String? activityLevel;
      if (profile.workoutType != null) {
        final w = profile.workoutType!.toLowerCase();
        if (w.contains('cardio') || w.contains('active')) activityLevel = 'active';
        else if (w.contains('strength') || w.contains('moderate')) activityLevel = 'moderate';
        else if (w.contains('light') || w.contains('yoga')) activityLevel = 'light';
        else if (w.contains('sedentary') || w.contains('none')) activityLevel = 'sedentary';
      }
      final level = activityLevel ?? 'moderate';
      final calories = GoalService.calculateCaloriesFromHealthData(
        weight: profile.weight!,
        height: profile.height!,
        age: age,
        gender: profile.gender!,
        activityLevel: level,
      );
      if (calories <= 0) return;
      final steps = GoalService.getStepsGoalFromProfile(
        calculatedCalories: calories,
        purpose: profile.purpose,
        workoutType: profile.workoutType,
      );
      final goalService = EnhancedGoalService(firestore: FirebaseFirestore.instance);
      await goalService.saveDailyGoals(
        stepCountGoalValue: steps,
        caloriesBurnGoalValue: calories,
        moveMinGoalValue: 30,
        isPaused: false,
        isGoalCompleted: false,
      );
      final macroService = MacroCalculationService(firestore: FirebaseFirestore.instance);
      await macroService.calculateAndSaveMacros(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        dailyCalories: calories,
        purpose: profile.purpose,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ProfilePage: Error recalculating goals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const ShimmerProfilePage()
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 24.h),
                  _buildSectionLabel('Personal info'),
                  _buildNameField(),
                  SizedBox(height: 16.h),
                  _buildDateField(),
                  SizedBox(height: 16.h),
                  _buildGenderRow(),
                  SizedBox(height: 24.h),
                  _buildSectionLabel('Health'),
                  _buildHeightWeightRow(),
                  SizedBox(height: 24.h),
                  _buildSectionLabel('Fitness goals'),
                  _buildWorkoutTypeChips(),
                  SizedBox(height: 16.h),
                  _buildPurposeChips(),
                  SizedBox(height: 32.h),
                  _buildSaveButton(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _profile?.photoUrl ?? FirebaseAuth.instance.currentUser?.photoURL;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48.r,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: CircleAvatar(
              radius: 44.r,
              backgroundColor: Colors.black,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(Icons.person_rounded, size: 40.sp, color: AppColors.primary)
                  : null,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _nameController.text.isEmpty ? 'Your profile' : _nameController.text,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: TextFormField(
        controller: _nameController,
        style: GoogleFonts.ubuntu(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: 'Full name',
          labelStyle: GoogleFonts.ubuntu(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 22.w),
            SizedBox(width: 16.w),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Date of birth',
              style: GoogleFonts.ubuntu(
                fontSize: 16.sp,
                color: _selectedDate != null ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14.w, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderRow() {
    return Row(
      children: [
        Expanded(child: _buildGenderOption('male', 'Male')),
        SizedBox(width: 12.w),
        Expanded(child: _buildGenderOption('female', 'Female')),
        SizedBox(width: 12.w),
        Expanded(child: _buildGenderOption('other', 'Other')),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedGender = value),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.8),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeightWeightRow() {
    return Row(
      children: [
        Expanded(
          child: _buildGoalStyleField(
            label: 'Height (cm)',
            controller: _heightController,
            icon: Icons.height,
            color: const Color(0xFF00D4AA),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildGoalStyleField(
            label: 'Weight (kg)',
            controller: _weightController,
            icon: Icons.monitor_weight_outlined,
            color: const Color(0xFFFF6B35),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStyleField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTypeChips() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _workoutTypes.map((type) {
        final isSelected = _selectedWorkoutType == type;
        return _buildChip(
          label: type,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedWorkoutType = type),
        );
      }).toList(),
    );
  }

  Widget _buildPurposeChips() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _purposes.map((purpose) {
        final isSelected = _selectedPurpose == purpose;
        return _buildChip(
          label: purpose,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedPurpose = purpose),
        );
      }).toList(),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.9),
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
        ),
        child: _isSaving
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                'Save changes',
                style: GoogleFonts.ubuntu(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
