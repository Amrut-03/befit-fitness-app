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
    
    // String? newMessage;
    // 
    // // Check for completion
    // if (widget.stepsPercentage >= 100.0) {
    //   newMessage = '🎉 Steps goal achieved! Amazing work!';
    // } else if (widget.caloriesPercentage >= 100.0) {
    //   newMessage = '🔥 Calories goal achieved! Keep it up!';
    // } else if (widget.moveMinPercentage >= 100.0) {
    //   newMessage = '💪 Move minutes goal achieved! You\'re unstoppable!';
    // } else {
    //   // Show progress messages
    //   final stepsRemaining = 10000 - widget.steps;
    //   final caloriesRemaining = 2000 - widget.calories;
    //   final moveMinRemaining = (widget.moveMin != null) ? 30 - widget.moveMin! : 30;
    //   
    //   if (widget.stepsPercentage >= 90.0 && stepsRemaining > 0) {
    //     newMessage = '🔥 ${stepsRemaining.toString()} steps to go! Almost there!';
    //   } else if (widget.caloriesPercentage >= 90.0 && caloriesRemaining > 0) {
    //     newMessage = '💪 ${caloriesRemaining.toStringAsFixed(0)} calories to go! You\'ve got this!';
    //   } else if (widget.moveMinPercentage >= 90.0 && moveMinRemaining > 0) {
    //     newMessage = '⚡ ${moveMinRemaining} minutes to go! Keep moving!';
    //   } else if (widget.stepsPercentage >= 75.0 && stepsRemaining > 0) {
    //     newMessage = '📈 Great progress! ${stepsRemaining.toString()} steps remaining';
    //   } else if (widget.caloriesPercentage >= 75.0 && caloriesRemaining > 0) {
    //     newMessage = '📈 Great progress! ${caloriesRemaining.toStringAsFixed(0)} calories remaining';
    //   } else if (widget.moveMinPercentage >= 75.0 && moveMinRemaining > 0) {
    //     newMessage = '📈 Great progress! ${moveMinRemaining} minutes remaining';
    //   } else if (widget.stepsPercentage >= 50.0) {
    //     newMessage = '🌟 Halfway there! Keep going!';
    //   } else if (widget.caloriesPercentage >= 50.0) {
    //     newMessage = '🌟 Halfway there! Keep going!';
    //   } else if (widget.moveMinPercentage >= 50.0) {
    //     newMessage = '🌟 Halfway there! Keep going!';
    //   }
    // }
    // 
    // if (newMessage != null && newMessage != _currentMessage) {
    //   _showMessage(newMessage);
    // }
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
    // Trigger confetti if controller is provided
    widget.confettiController?.play();
    
    // Show celebration message
    // String message;
    // switch (type) {
    //   case 'steps':
    //     message = '🎉 Steps goal achieved! Amazing work!';
    //     break;
    //   case 'calories':
    //     message = '🔥 Calories goal achieved! Keep it up!';
    //     break;
    //   case 'moveMin':
    //     message = '💪 Move minutes goal achieved! You\'re unstoppable!';
    //     break;
    //   default:
    //     message = '🎉 Goal achieved!';
    // }
    // 
    // // Show SnackBar for milestone celebration at the top
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         message,
    //         style: GoogleFonts.ubuntu(
    //           fontWeight: FontWeight.w600,
    //         ),
    //       ),
    //       backgroundColor: Colors.green,
    //       duration: const Duration(seconds: 3),
    //       behavior: SnackBarBehavior.floating,
    //       margin: EdgeInsets.only(
    //         top: MediaQuery.of(context).padding.top + 20.h,
    //         left: 20.w,
    //         right: 20.w,
    //       ),
    //     ),
    //   );
    // }
    // 
    // _showMessage(message);
    
    // Stop confetti after 2 seconds
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

