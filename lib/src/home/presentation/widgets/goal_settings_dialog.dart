import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/src/home/data/services/goal_service.dart';

/// Dialog for editing daily fitness goals
class GoalSettingsDialog extends StatefulWidget {
  final String goalType; // 'steps', 'calories', 'moveMin'
  final double currentGoal;
  final Function(double) onGoalUpdated;

  const GoalSettingsDialog({
    super.key,
    required this.goalType,
    required this.currentGoal,
    required this.onGoalUpdated,
  });

  @override
  State<GoalSettingsDialog> createState() => _GoalSettingsDialogState();
}

class _GoalSettingsDialogState extends State<GoalSettingsDialog> {
  late TextEditingController _goalController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: widget.currentGoal.toStringAsFixed(widget.goalType == 'calories' ? 0 : 0),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  String get _goalLabel {
    switch (widget.goalType) {
      case 'steps':
        return 'Daily Steps Goal';
      case 'calories':
        return 'Daily Calories Goal';
      case 'moveMin':
        return 'Daily Move Minutes Goal';
      default:
        return 'Goal';
    }
  }

  String get _goalUnit {
    switch (widget.goalType) {
      case 'steps':
        return 'steps';
      case 'calories':
        return 'cal';
      case 'moveMin':
        return 'minutes';
      default:
        return '';
    }
  }

  double? _validateAndParse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final newGoal = _validateAndParse(_goalController.text);
    if (newGoal == null) return;

    // Save to service
    switch (widget.goalType) {
      case 'steps':
        await GoalService.setStepsGoal(newGoal.toInt());
        break;
      case 'calories':
        await GoalService.setCaloriesGoal(newGoal);
        break;
      case 'moveMin':
        await GoalService.setMoveMinGoal(newGoal.toInt());
        break;
    }

    widget.onGoalUpdated(newGoal);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit $_goalLabel',
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  labelText: _goalLabel,
                  labelStyle: GoogleFonts.ubuntu(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                  hintText: 'Enter $_goalUnit',
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.white30,
                    fontSize: 14.sp,
                  ),
                  suffixText: _goalUnit,
                  suffixStyle: GoogleFonts.ubuntu(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  final parsed = _validateAndParse(value);
                  if (parsed == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.ubuntu(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

