import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/data/services/enhanced_goal_service.dart';

/// Bottom sheet for editing daily goals with all validations and features
class GoalEditingBottomSheet extends StatefulWidget {
  final EnhancedGoalService goalService;
  final Map<String, dynamic> currentGoals;
  final Map<String, dynamic>? smartSuggestions;
  final Function(Map<String, dynamic>) onGoalSaved;

  const GoalEditingBottomSheet({
    super.key,
    required this.goalService,
    required this.currentGoals,
    this.smartSuggestions,
    required this.onGoalSaved,
  });

  @override
  State<GoalEditingBottomSheet> createState() => _GoalEditingBottomSheetState();
}

class _GoalEditingBottomSheetState extends State<GoalEditingBottomSheet> {
  late TextEditingController _stepsController;
  late TextEditingController _caloriesController;
  late TextEditingController _moveMinController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPaused = false;
  String? _pauseReason;
  bool _hasEditedToday = false;
  bool _isBeforeNoon = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(text: widget.currentGoals['steps'].toString());
    _caloriesController = TextEditingController(text: widget.currentGoals['calories'].toStringAsFixed(0));
    _moveMinController = TextEditingController(text: widget.currentGoals['moveMin'].toString());
    _checkEditStatus();
  }

  Future<void> _checkEditStatus() async {
    final hasEdited = await widget.goalService.hasEditedGoalToday();
    final isBeforeNoon = DateTime.now().hour < 12;
    setState(() {
      _hasEditedToday = hasEdited;
      _isBeforeNoon = isBeforeNoon;
    });
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _moveMinController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasEditedToday) {
      setState(() {
        _errorMessage = 'You can only edit your goal once per day. Changes will apply ${_isBeforeNoon ? 'today' : 'tomorrow'}.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final steps = int.parse(_stepsController.text);
      final calories = double.parse(_caloriesController.text);
      final moveMin = int.parse(_moveMinController.text);

      // Validate
      final stepsError = widget.goalService.validateStepsGoal(steps);
      final caloriesError = widget.goalService.validateCaloriesGoal(calories);
      final moveMinError = widget.goalService.validateMoveMinGoal(moveMin);

      if (stepsError != null || caloriesError != null || moveMinError != null) {
        setState(() {
          _errorMessage = stepsError ?? caloriesError ?? moveMinError;
          _isLoading = false;
        });
        return;
      }

      // Save goals
      if (!_isPaused) {
        await widget.goalService.saveGoal(
          goalType: 'steps',
          goalValue: steps,
        );
        await widget.goalService.saveGoal(
          goalType: 'calories',
          goalValue: calories,
        );
        await widget.goalService.saveGoal(
          goalType: 'moveMin',
          goalValue: moveMin,
        );
      } else {
        // Save paused state
        await widget.goalService.saveGoal(
          goalType: 'steps',
          goalValue: steps,
          isPaused: true,
          pauseReason: _pauseReason,
        );
      }

      widget.onGoalSaved({
        'steps': steps,
        'calories': calories,
        'moveMin': moveMin,
        'isPaused': _isPaused,
        'pauseReason': _pauseReason,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBeforeNoon 
                ? 'Goals updated for today!' 
                : 'Goals will be applied tomorrow!',
              style: GoogleFonts.ubuntu(),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save goals: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applySmartSuggestion() {
    if (widget.smartSuggestions != null) {
      setState(() {
        _stepsController.text = widget.smartSuggestions!['steps'].toString();
        _caloriesController.text = widget.smartSuggestions!['calories'].toStringAsFixed(0);
        _moveMinController.text = widget.smartSuggestions!['moveMin'].toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20.w,
              right: 20.w,
              top: 12.h,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Daily Goals',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.smartSuggestions != null)
                  TextButton.icon(
                    onPressed: _applySmartSuggestion,
                    icon: Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18.sp),
                    label: Text(
                      'Smart Goal',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            // Instruction text
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isBeforeNoon
                          ? 'Editing before 12 PM will apply to today. After 12 PM, changes apply tomorrow.'
                          : 'Editing after 12 PM will apply to tomorrow.',
                      style: GoogleFonts.ubuntu(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_hasEditedToday) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'You can only edit your goal once per day.',
                        style: GoogleFonts.ubuntu(
                          fontSize: 11.sp,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 11.sp,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
            // Steps goal
            _buildGoalField(
              label: 'Daily Steps Goal',
              controller: _stepsController,
              icon: Icons.directions_walk,
              color: const Color(0xFF00D4AA),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter steps goal';
                final steps = int.tryParse(value);
                if (steps == null) return 'Please enter a valid number';
                return widget.goalService.validateStepsGoal(steps);
              },
            ),
            SizedBox(height: 16.h),
            // Calories goal
            _buildGoalField(
              label: 'Daily Calories Goal',
              controller: _caloriesController,
              icon: Icons.local_fire_department,
              color: const Color(0xFFFF6B35),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter calories goal';
                final calories = double.tryParse(value);
                if (calories == null) return 'Please enter a valid number';
                return widget.goalService.validateCaloriesGoal(calories);
              },
            ),
            SizedBox(height: 16.h),
            // Move minutes goal
            _buildGoalField(
              label: 'Daily Move Minutes Goal',
              controller: _moveMinController,
              icon: Icons.fitness_center,
              color: const Color(0xFFFF006E),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter move minutes goal';
                final moveMin = int.tryParse(value);
                if (moveMin == null) return 'Please enter a valid number';
                return widget.goalService.validateMoveMinGoal(moveMin);
              },
            ),
            SizedBox(height: 20.h),
            // Pause goal option
            CheckboxListTile(
              value: _isPaused,
              onChanged: _hasEditedToday ? null : (value) {
                setState(() {
                  _isPaused = value ?? false;
                  if (!_isPaused) _pauseReason = null;
                });
              },
              title: Text(
                'Pause Goal Today',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: _isPaused
                  ? DropdownButtonFormField<String>(
                      value: _pauseReason,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        labelStyle: GoogleFonts.ubuntu(color: Colors.white.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                      ),
                      dropdownColor: Colors.black,
                      style: GoogleFonts.ubuntu(color: Colors.white),
                      items: ['Sick', 'Rest Day', 'Other'].map((reason) {
                        return DropdownMenuItem(
                          value: reason.toLowerCase().replaceAll(' ', '_'),
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _pauseReason = value;
                        });
                      },
                    )
                  : null,
              activeColor: AppColors.primary,
            ),
            SizedBox(height: 20.h),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _hasEditedToday ? null : _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        'Save Goals',
                        style: GoogleFonts.ubuntu(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    ),
        );
      },
    );
  }

  Widget _buildGoalField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    required String? Function(String?) validator,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
              validator: validator,
              keyboardType: TextInputType.number,
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
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

