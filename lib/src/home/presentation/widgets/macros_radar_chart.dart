import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

/// Education bottom sheet for macros radar chart
void showMacrosRadarEducationBottomSheet(BuildContext context) {
  showModalBottomSheet(
    backgroundColor: Colors.black,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.w,
          right: 20.w,
          top: 12.h,
        ),
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
            Text(
              'About Macros Radar Chart',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            _buildEducationItem(
              context,
              icon: Icons.grain,
              title: 'Carbohydrates',
              description: 'Shows your daily carb consumption percentage. The orange color represents carbs. Aim to stay within your daily goal for balanced nutrition.',
              color: const Color(0xFFFF6B35),
            ),
            SizedBox(height: 16.h),
            _buildEducationItem(
              context,
              icon: Icons.fitness_center,
              title: 'Protein',
              description: 'Displays your protein intake percentage. The pink color represents protein. Essential for muscle repair and growth.',
              color: const Color(0xFFFF006E),
            ),
            SizedBox(height: 16.h),
            _buildEducationItem(
              context,
              icon: Icons.water_drop,
              title: 'Fat',
              description: 'Tracks your fat consumption percentage. The teal color represents fat. Healthy fats are important for energy and nutrient absorption.',
              color: const Color(0xFF00D4AA),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'The radar chart shows your daily macro consumption as percentages. Each axis represents one macro, and the shape shows how close you are to your daily goals.',
                      style: GoogleFonts.ubuntu(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      );
    },
  );
}

Widget _buildEducationItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
  required Color color,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                style: GoogleFonts.ubuntu(
                  fontSize: 13.sp,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Radar chart widget for displaying macro consumption percentages
class MacrosRadarChart extends StatelessWidget {
  final double carbsPercentage;
  final double proteinPercentage;
  final double fatPercentage;
  final double? carbsGoal;
  final double? proteinGoal;
  final double? fatGoal;
  final VoidCallback? onTap;

  const MacrosRadarChart({
    super.key,
    required this.carbsPercentage,
    required this.proteinPercentage,
    required this.fatPercentage,
    this.carbsGoal,
    this.proteinGoal,
    this.fatGoal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp percentages to 0-100
    final carbs = carbsPercentage.clamp(0.0, 100.0);
    final protein = proteinPercentage.clamp(0.0, 100.0);
    final fat = fatPercentage.clamp(0.0, 100.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.radar,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Macros Consumption',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.textOnPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Daily progress tracking',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.textOnPrimary.withOpacity(0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                onPressed: () {
                  showMacrosRadarEducationBottomSheet(context);
                },
                tooltip: 'Learn more about macros',
              ),
            ],
          ),
          SizedBox(height: 28.h),
          SizedBox(
            height: 280.h,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    entryRadius: 0,
                    fillColor: const Color(0xFF00BCD4).withOpacity(0.3),
                    borderColor: const Color(0xFF00BCD4),
                    borderWidth: 4,
                    dataEntries: [
                      RadarEntry(value: carbs),
                      RadarEntry(value: protein),
                      RadarEntry(value: fat),
                    ],
                  ),
                ],
                radarTouchData: RadarTouchData(
                  touchCallback: (FlTouchEvent event, response) {
                    // Handle touch if needed
                  },
                ),
                radarBorderData: BorderSide(
                  color: const Color(0xFF00D4AA).withOpacity(0.5),
                  width: 2.5,
                ),
                titlePositionPercentageOffset: 0.18,
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(
                        text: 'CARBS',
                        angle: angle,
                        positionPercentageOffset: 0.12,
                      );
                    case 1:
                      return RadarChartTitle(
                        text: 'PROTEIN',
                        angle: angle,
                        positionPercentageOffset: 0.12,
                      );
                    case 2:
                      return RadarChartTitle(
                        text: 'FAT',
                        angle: angle,
                        positionPercentageOffset: 0.12,
                      );
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
                titleTextStyle: GoogleFonts.ubuntu(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                tickCount: 5,
                ticksTextStyle: GoogleFonts.ubuntu(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                ),
                tickBorderData: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: const Color(0xFFFF006E).withOpacity(0.5),
                    width: 2.5,
                  ),
                ),
                gridBorderData: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // Legend with enhanced design
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  'Carbs',
                  carbs,
                  const Color(0xFFFF6B35),
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildLegendItem(
                  'Protein',
                  protein,
                  const Color(0xFFFF006E),
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildLegendItem(
                  'Fat',
                  fat,
                  const Color(0xFF00D4AA),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double percentage, Color color) {
    return Column(
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.ubuntu(
            color: AppColors.textOnPrimary.withOpacity(0.9),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: GoogleFonts.ubuntu(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}


