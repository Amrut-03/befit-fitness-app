import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

/// Widget for displaying contextual motivation messages
class MotivationMessageWidget extends StatefulWidget {
  final double stepsPercentage;
  final double caloriesPercentage;
  final double moveMinPercentage;
  final int steps;
  final double calories;
  final int? moveMin;
  final ConfettiController? confettiController;

  const MotivationMessageWidget({
    super.key,
    required this.stepsPercentage,
    required this.caloriesPercentage,
    required this.moveMinPercentage,
    required this.steps,
    required this.calories,
    this.moveMin,
    this.confettiController,
  });

  @override
  State<MotivationMessageWidget> createState() => _MotivationMessageWidgetState();
}

class _MotivationMessageWidgetState extends State<MotivationMessageWidget>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String?> _currentMessage = ValueNotifier<String?>(null);
  Timer? _messageTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasCelebratedSteps = false;
  bool _hasCelebratedCalories = false;
  bool _hasCelebratedMoveMin = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _checkAndShowMessage();
  }

  @override
  void didUpdateWidget(MotivationMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check for milestone achievements
    if (widget.stepsPercentage >= 100.0 && oldWidget.stepsPercentage < 100.0 && !_hasCelebratedSteps) {
      _celebrateMilestone('steps');
      _hasCelebratedSteps = true;
    }
    if (widget.caloriesPercentage >= 100.0 && oldWidget.caloriesPercentage < 100.0 && !_hasCelebratedCalories) {
      _celebrateMilestone('calories');
      _hasCelebratedCalories = true;
    }
    if (widget.moveMinPercentage >= 100.0 && oldWidget.moveMinPercentage < 100.0 && !_hasCelebratedMoveMin) {
      _celebrateMilestone('moveMin');
      _hasCelebratedMoveMin = true;
    }
    
    _checkAndShowMessage();
  }

  void _checkAndShowMessage() {
    // Reset celebration flags if percentages drop below 100
    if (widget.stepsPercentage < 100.0) _hasCelebratedSteps = false;
    if (widget.caloriesPercentage < 100.0) _hasCelebratedCalories = false;
    if (widget.moveMinPercentage < 100.0) _hasCelebratedMoveMin = false;
  }

  void _showMessage(String message) {
    _currentMessage.value = message;
    
    _messageTimer?.cancel();
    _fadeController.forward();
    
    _messageTimer = Timer(const Duration(seconds: 3), () {
      _fadeController.reverse().then((_) {
        if (mounted) {
          _currentMessage.value = null;
        }
      });
    });
  }

  void _celebrateMilestone(String type) {
    widget.confettiController?.play();
    Timer(const Duration(seconds: 2), () {
      widget.confettiController?.stop();
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _fadeController.dispose();
    _currentMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _currentMessage,
      builder: (context, currentMessage, child) {
        if (currentMessage == null) {
          return const SizedBox.shrink();
        }
        
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      currentMessage,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

