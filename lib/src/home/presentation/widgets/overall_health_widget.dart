import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Widget displaying overall health metrics with concentric arcs
class OverallHealthWidget extends StatefulWidget {
  final double stepsPercentage;
  final double caloriesPercentage;
  final double moveMinPercentage;
  final double? overallHealthPercentage;
  final Color backgroundColor;
  final Color innerColor;
  final Color middleColor;
  final Color outerColor;
  final double strokeWidth;
  final double containerHeight;
  final double containerWidth;
  final double? arcSize;

  const OverallHealthWidget({
    super.key,
    required this.stepsPercentage,
    required this.caloriesPercentage,
    required this.moveMinPercentage,
    this.overallHealthPercentage,
    this.backgroundColor = Colors.black,
    this.innerColor = const Color(0xFF00D4AA), // Teal for steps (inner)
    this.middleColor = const Color(0xFFFF6B35), // Orange for calories (middle)
    this.outerColor = const Color(0xFFFF006E), // Pink for moveMin (outer)
    this.strokeWidth = 12.0,
    this.containerHeight = 250,
    this.containerWidth = 230,
    this.arcSize,
  });

  @override
  State<OverallHealthWidget> createState() => _OverallHealthWidgetState();
}

class _OverallHealthWidgetState extends State<OverallHealthWidget> {
  bool _showTooltip = false;

  @override
  Widget build(BuildContext context) {
    // Convert percentages to sweep angles (0-360 degrees)
    // Inner circle = Steps, Middle circle = Calories, Outer circle = Move Min
    final stepsSweepAngle = (widget.stepsPercentage / 100) * 360;
    final caloriesSweepAngle = (widget.caloriesPercentage / 100) * 360;
    final moveMinSweepAngle = (widget.moveMinPercentage / 100) * 360;
    final arcSizeValue = widget.arcSize ?? 190.w;

    // Check if all values are empty (all percentages are 0)
    final bool isEmpty = widget.stepsPercentage == 0 &&
        widget.caloriesPercentage == 0 &&
        widget.moveMinPercentage == 0;

    return Column(
      children: [
        Container(
          height: widget.containerHeight.h,
          width: 250.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.backgroundColor,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showTooltip = !_showTooltip;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
              // Tooltip
              if (_showTooltip)
                Positioned(
                  top: 40.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTooltipRow('Steps Count', widget.innerColor),
                        SizedBox(height: 6.h),
                        _buildTooltipRow('Calories Burn', widget.middleColor),
                        SizedBox(height: 6.h),
                        _buildTooltipRow('Move Min', widget.outerColor),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: CustomPaint(
                      size: Size(arcSizeValue, arcSizeValue),
                      painter: ConcentricArcsPainter(
                        innerSweepAngle: stepsSweepAngle,
                        middleSweepAngle: caloriesSweepAngle,
                        outerSweepAngle: moveMinSweepAngle,
                        innerColor: widget.innerColor,
                        middleColor: widget.middleColor,
                        outerColor: widget.outerColor,
                        strokeWidth: widget.strokeWidth,
                      ),
                    ),
                ),
                // Blur overlay when all values are empty
                if (isEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

  Widget _buildTooltipRow(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for drawing three concentric circular arcs
class ConcentricArcsPainter extends CustomPainter {
  final double innerSweepAngle;
  final double middleSweepAngle;
  final double outerSweepAngle;
  final Color innerColor;
  final Color middleColor;
  final Color outerColor;
  final double strokeWidth;

  ConcentricArcsPainter({
    required this.innerSweepAngle,
    required this.middleSweepAngle,
    required this.outerSweepAngle,
    required this.innerColor,
    required this.middleColor,
    required this.outerColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = -math.pi / 2; // Start from top (12 o'clock)
    const greyColor = Color(0xFFE0E0E0); // Light grey for unfilled portions

    // Calculate radii for concentric circles
    final outerRadius = (size.width / 2) - strokeWidth / 2;
    final middleRadius = outerRadius - strokeWidth - 8;
    final innerRadius = middleRadius - strokeWidth - 8;

    // Calculate remaining angles (360 - sweep angle)
    final outerRemainingAngle = 360 - outerSweepAngle;
    final middleRemainingAngle = 360 - middleSweepAngle;
    final innerRemainingAngle = 360 - innerSweepAngle;

    // Draw outer arc background (grey) - unfilled portion
    final outerGreyPaint = Paint()
      ..color = greyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final outerStartAngle = startAngle + (math.pi / 6); // Start slightly to the right
    final outerFilledAngle = outerSweepAngle * math.pi / 180;
    final outerGreyAngle = outerRemainingAngle * math.pi / 180;
    
    // Draw grey background (unfilled portion)
    if (outerRemainingAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        outerStartAngle + outerFilledAngle,
        outerGreyAngle,
        false,
        outerGreyPaint,
      );
    }

    // Draw outer arc (pink) - filled portion
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      outerStartAngle,
      outerFilledAngle,
      false,
      outerPaint,
    );

    // Draw middle arc background (grey) - unfilled portion
    final middleGreyPaint = Paint()
      ..color = greyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final middleStartAngle = startAngle - (math.pi / 12); // Start slightly to the left
    final middleFilledAngle = middleSweepAngle * math.pi / 180;
    final middleGreyAngle = middleRemainingAngle * math.pi / 180;
    
    // Draw grey background (unfilled portion)
    if (middleRemainingAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: middleRadius),
        middleStartAngle + middleFilledAngle,
        middleGreyAngle,
        false,
        middleGreyPaint,
      );
    }

    // Draw middle arc (orange) - filled portion
    final middlePaint = Paint()
      ..color = middleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: middleRadius),
      middleStartAngle,
      middleFilledAngle,
      false,
      middlePaint,
    );

    // Draw inner arc background (grey) - unfilled portion
    final innerGreyPaint = Paint()
      ..color = greyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final innerStartAngle = startAngle - (math.pi / 8); // Start slightly to the left
    final innerFilledAngle = innerSweepAngle * math.pi / 180;
    final innerGreyAngle = innerRemainingAngle * math.pi / 180;
    
    // Draw grey background (unfilled portion)
    if (innerRemainingAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        innerStartAngle + innerFilledAngle,
        innerGreyAngle,
        false,
        innerGreyPaint,
      );
    }

    // Draw inner arc (teal) - filled portion
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      innerStartAngle,
      innerFilledAngle,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(ConcentricArcsPainter oldDelegate) {
    return oldDelegate.innerSweepAngle != innerSweepAngle ||
        oldDelegate.middleSweepAngle != middleSweepAngle ||
        oldDelegate.outerSweepAngle != outerSweepAngle ||
        oldDelegate.innerColor != innerColor ||
        oldDelegate.middleColor != middleColor ||
        oldDelegate.outerColor != outerColor;
  }
}

