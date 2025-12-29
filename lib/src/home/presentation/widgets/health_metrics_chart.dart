import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

/// Chart type enum
enum ChartType {
  weight,
  calories,
  sleep,
}

/// Model for chart data point
class ChartDataPoint {
  final double value;
  final String label;

  const ChartDataPoint({
    required this.value,
    required this.label,
  });
}

/// Model for chart series
class ChartSeries {
  final String name;
  final List<ChartDataPoint> dataPoints;
  final Color color;

  const ChartSeries({
    required this.name,
    required this.dataPoints,
    required this.color,
  });
}

/// Widget displaying health metrics chart (Weight, Calories, Sleep)
class HealthMetricsChart extends StatefulWidget {
  final ChartSeries series;
  final String title;
  final String subtitle;
  final ChartType chartType;
  final bool isWeekly;

  const HealthMetricsChart({
    super.key,
    required this.series,
    required this.chartType,
    this.title = 'Health Metrics',
    this.subtitle = 'Track your progress',
    this.isWeekly = true,
  });

  @override
  State<HealthMetricsChart> createState() => _HealthMetricsChartState();
}

class _HealthMetricsChartState extends State<HealthMetricsChart> {
  int? _touchedIndex;
  bool _isWeekly = true;

  @override
  void initState() {
    super.initState();
    _isWeekly = widget.isWeekly;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = _getMaxValue();
    final minValue = _getMinValue();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Subtitle with Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.ubuntu(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.title,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Week/Month Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Week', true),
                    _buildToggleButton('Month', false),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          // Chart
          SizedBox(
            height: 190.h,
            child: LineChart(
              _buildChartData(maxValue, minValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isWeek) {
    final isSelected = _isWeekly == isWeek;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekly = isWeek;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? widget.series.color : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(double maxValue, double minValue) {
    final dataPoints = _isWeekly 
        ? _getWeeklyDataPoints() 
        : _getMonthlyDataPoints();
    
    // Get the interval and fixed min/max based on chart type
    final interval = _getYAxisInterval();
    final adjustedMin = _getMinValue();
    final adjustedMax = _getMaxValue();
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < dataPoints.length) {
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    dataPoints[index].label,
                    style: GoogleFonts.ubuntu(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: interval,
            getTitlesWidget: (value, meta) {
              // Only show values that are multiples of the interval and within range
              if ((value % interval) < 0.01 && value >= adjustedMin && value <= adjustedMax) {
                return Text(
                  _formatYAxisValue(value),
                  style: GoogleFonts.ubuntu(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      minX: 0,
      maxX: (dataPoints.length - 1).toDouble(),
      minY: adjustedMin,
      maxY: adjustedMax,
      lineBarsData: [
        LineChartBarData(
          spots: dataPoints.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.value);
          }).toList(),
          isCurved: true,
          color: widget.series.color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: widget.series.color.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final pointIndex = touchedSpot.x.toInt();
              final dataPoints = _isWeekly 
                  ? _getWeeklyDataPoints() 
                  : _getMonthlyDataPoints();
              
              if (pointIndex >= 0 && pointIndex < dataPoints.length) {
                return LineTooltipItem(
                  '${widget.series.name}\n${_formatYAxisValue(touchedSpot.y)}',
                  GoogleFonts.ubuntu(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.series.color,
                  ),
                );
              }
              return null;
            }).toList();
          },
          tooltipPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          tooltipMargin: 8,
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          if (!event.isInterestedForInteractions ||
              touchResponse == null ||
              touchResponse.lineBarSpots == null) {
            setState(() {
              _touchedIndex = null;
            });
            return;
          }
          setState(() {
            _touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
          });
        },
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
          return indicators.map((int index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: barData.color,
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final dotColor = barData.color ?? Colors.blue;
                  return FlDotCirclePainter(
                    radius: 8,
                    color: dotColor,
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  List<ChartDataPoint> _getWeeklyDataPoints() {
    return widget.series.dataPoints;
  }

  List<ChartDataPoint> _getMonthlyDataPoints() {
    // For monthly view, show only odd months: Jan, Mar, May, Jul, Sep, Nov
    final months = ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'];
    
    // Generate monthly data with realistic variations based on chart type
    return months.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      
      double value;
      switch (widget.chartType) {
        case ChartType.weight:
          // Weight: 79-85 kg range with monthly variation
          value = 79 + (index % 6) * 1.0 + (index % 3) * 0.2;
          break;
        case ChartType.calories:
          // Calories: 200-800 kcal range with monthly variation
          value = 200 + (index % 6) * 120.0;
          break;
        case ChartType.sleep:
          // Sleep: 6-9 hours range with monthly variation
          value = 6 + (index % 6) * 0.5;
          break;
      }
      
      return ChartDataPoint(
        value: value,
        label: month,
      );
    }).toList();
  }

  double _getMaxValue() {
    // Fixed Y-axis ranges for all graphs
    switch (widget.chartType) {
      case ChartType.weight:
        return 200.0; // End at 200
      case ChartType.calories:
        return 4000.0; // End at 4000
      case ChartType.sleep:
        return 20.0; // End at 20
    }
  }

  double _getMinValue() {
    // All graphs start from 0
    return 0.0;
  }

  double _getYAxisInterval() {
    switch (widget.chartType) {
      case ChartType.weight:
        return 20.0; // 0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200
      case ChartType.calories:
        return 500.0; // 0, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000
      case ChartType.sleep:
        return 2.0; // 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20
    }
  }


  String _formatYAxisValue(double value) {
    switch (widget.chartType) {
      case ChartType.weight:
        // Weight: show as "85", "83", "81", "79" (kg)
        return value.toInt().toString();
      case ChartType.calories:
        // Calories: show as "800", "600", "400", "200" (kcal)
        return value.toInt().toString();
      case ChartType.sleep:
        // Sleep: show as "9", "8", "7", "6" (hrs)
        return value.toInt().toString();
    }
  }
}


