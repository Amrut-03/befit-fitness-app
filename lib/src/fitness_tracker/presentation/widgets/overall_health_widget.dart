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
  final int steps;
  final double calories;
  final int? moveMin;
  final String? previousSteps;
  final String? previousCalories;
  final String? previousMoveMin;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;

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
    required this.steps,
    required this.calories,
    this.moveMin,
    this.previousSteps,
    this.previousCalories,
    this.previousMoveMin,
    this.onTap,
    this.onInfoTap,
  });

  @override
  State<OverallHealthWidget> createState() => _OverallHealthWidgetState();
}

class _OverallHealthWidgetState extends State<OverallHealthWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _stepsAnimation;
  late Animation<double> _caloriesAnimation;
  late Animation<double> _moveMinAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _stepsAnimation = Tween<double>(
      begin: 0,
      end: widget.stepsPercentage / 100 * 360,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _caloriesAnimation = Tween<double>(
      begin: 0,
      end: widget.caloriesPercentage / 100 * 360,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _moveMinAnimation = Tween<double>(
      begin: 0,
      end: widget.moveMinPercentage / 100 * 360,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(OverallHealthWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepsPercentage != widget.stepsPercentage ||
        oldWidget.caloriesPercentage != widget.caloriesPercentage ||
        oldWidget.moveMinPercentage != widget.moveMinPercentage) {
      _stepsAnimation = Tween<double>(
        begin: oldWidget.stepsPercentage / 100 * 360,
        end: widget.stepsPercentage / 100 * 360,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _caloriesAnimation = Tween<double>(
        begin: oldWidget.caloriesPercentage / 100 * 360,
        end: widget.caloriesPercentage / 100 * 360,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _moveMinAnimation = Tween<double>(
        begin: oldWidget.moveMinPercentage / 100 * 360,
        end: widget.moveMinPercentage / 100 * 360,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Calculate overall health percentage from the three metrics
  double _calculateOverallPercentage() {
    if (widget.overallHealthPercentage != null) {
      return widget.overallHealthPercentage!;
    }
    // Calculate average of all three percentages
    final percentages = [
      widget.stepsPercentage,
      widget.caloriesPercentage,
      widget.moveMinPercentage,
    ];
    final sum = percentages.reduce((a, b) => a + b);
    return (sum / percentages.length).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final arcSizeValue = widget.arcSize ?? 190.w;


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
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(arcSizeValue, arcSizeValue),
                            painter: ConcentricArcsPainter(
                              innerSweepAngle: _stepsAnimation.value,
                              middleSweepAngle: _caloriesAnimation.value,
                              outerSweepAngle: _moveMinAnimation.value,
                              innerColor: widget.innerColor,
                              middleColor: widget.middleColor,
                              outerColor: widget.outerColor,
                              strokeWidth: widget.strokeWidth,
                            ),
                          ),
                          // Center text showing overall percentage and remaining
                          Text(
                            '${_calculateOverallPercentage().toStringAsFixed(0)}%',
                            style: GoogleFonts.ubuntu(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Info icon on top so it receives taps first (was behind chart and not tappable)
              if (widget.onInfoTap != null)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onInfoTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
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
                ),
            ],
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
