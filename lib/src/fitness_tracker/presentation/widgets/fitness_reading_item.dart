import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable widget for displaying a fitness reading item (Steps, Calories, Heart Rate)
class FitnessReadingItem extends StatefulWidget {
  final VoidCallback onTap;
  final String lottieAsset;
  final String value;
  final String label;
  final double? lottieHeight;
  final double? lottieWidth;
  final double? topSpacing;
  final double? bottomSpacing;
  final String? previousValue; // For trend calculation
  final bool? isPositiveTrend; // Optional: explicitly set trend

  const FitnessReadingItem({
    super.key,
    required this.onTap,
    required this.lottieAsset,
    required this.value,
    required this.label,
    this.lottieHeight,
    this.lottieWidth,
    this.topSpacing,
    this.bottomSpacing,
    this.previousValue,
    this.isPositiveTrend,
  });

  @override
  State<FitnessReadingItem> createState() => _FitnessReadingItemState();
}

class _FitnessReadingItemState extends State<FitnessReadingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;
  double _previousValue = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _translateAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Parse initial value
    _previousValue = _parseValue(widget.value);
  }

  double _parseValue(String value) {
    try {
      // Handle formatted values like "1.2K", "1.5M"
      if (value.endsWith('K')) {
        return double.parse(value.replaceAll('K', '')) * 1000;
      } else if (value.endsWith('M')) {
        return double.parse(value.replaceAll('M', '')) * 1000000;
      }
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }

  bool _calculateTrend() {
    if (widget.isPositiveTrend != null) {
      return widget.isPositiveTrend!;
    }
    
    if (widget.previousValue == null) return false;
    
    try {
      final current = _parseValue(widget.value);
      final previous = _parseValue(widget.previousValue!);
      return current > previous;
    } catch (e) {
      return false;
    }
  }

  void _handleTap() {
    // Show tap feedback message
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         '${widget.label}: ${widget.value}',
    //         style: GoogleFonts.ubuntu(
    //           fontWeight: FontWeight.w500,
    //         ),
    //       ),
    //       backgroundColor: Colors.black87,
    //       duration: const Duration(milliseconds: 800),
    //       behavior: SnackBarBehavior.floating,
    //       margin: EdgeInsets.only(
    //         bottom: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 120,
    //         left: 20.w,
    //         right: 20.w,
    //       ),
    //     ),
    //   );
    // }
    
    setState(() {
      _isAnimating = true;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        setState(() {
          _isAnimating = false;
        });
      });
    });
    
    widget.onTap();
  }

  @override
  void didUpdateWidget(FitnessReadingItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newValue = _parseValue(widget.value);
      if (newValue != _previousValue) {
        _previousValue = newValue;
        // Trigger number animation
        _animationController.forward(from: 0.0).then((_) {
          _animationController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPositiveTrend = _calculateTrend();
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _translateAnimation.value),
              child: Transform.scale(
                scale: _isAnimating ? _scaleAnimation.value : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.topSpacing != null) SizedBox(height: widget.topSpacing),
                    SizedBox(
                      height: widget.lottieHeight ?? 35.h,
                      width: widget.lottieWidth,
                      child: LottieBuilder.asset(widget.lottieAsset),
                    ),
                    SizedBox(height: widget.bottomSpacing ?? 5.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.value,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (widget.previousValue != null || widget.isPositiveTrend != null) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            hasPositiveTrend ? Icons.trending_up : Icons.trending_down,
                            color: hasPositiveTrend ? Colors.green : Colors.red,
                            size: 12.sp,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      widget.label,
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}
