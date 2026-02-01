import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/shimmer_widget.dart';

/// Chart type enum
enum ChartType {
  weight,
  calories,
  heartRate,
  steps,
}

/// Model for chart data point
class ChartDataPoint {
  final double? value; // Nullable to handle missing data
  final String label;
  final bool isMissing; // True if this day has no data
  final bool isAnomaly; // True if value is an outlier

  const ChartDataPoint({
    this.value,
    required this.label,
    this.isMissing = false,
    this.isAnomaly = false,
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

/// Chart state enum
enum ChartState {
  empty,
  loading,
  error,
  hasData,
}

/// Widget displaying health metrics chart (Weight, Calories, Heart rate, Steps)
class HealthMetricsChart extends StatefulWidget {
  final ChartSeries series;
  final String title;
  final String subtitle;
  final ChartType chartType;
  final bool isWeekly;
  final ChartState state;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Map<String, String>? summaryMetrics; // e.g., {'avg': '72 bpm', 'trend': '+5 vs last week'}
  /// When set (e.g. for weight chart), shows a plus icon instead of Week/Month toggle; called when user taps to add/update weight.
  final VoidCallback? onAddTap;
  /// When true, renders a bar chart instead of a line chart (e.g. for Steps, Heart rate).
  final bool useBarChart;

  const HealthMetricsChart({
    super.key,
    required this.series,
    required this.chartType,
    this.title = 'Health Metrics',
    this.subtitle = 'Track your progress',
    this.isWeekly = true,
    this.state = ChartState.hasData,
    this.errorMessage,
    this.onRetry,
    this.summaryMetrics,
    this.onAddTap,
    this.useBarChart = false,
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
    final prefersReducedMotion = MediaQuery.of(context).disableAnimations;
    final highContrast = MediaQuery.of(context).highContrast;

    // Handle different states
    if (widget.state == ChartState.empty) {
      return _buildEmptyState();
    }
    
    if (widget.state == ChartState.loading) {
      return _buildLoadingState();
    }
    
    if (widget.state == ChartState.error) {
      return _buildErrorState();
    }

    // Check if we have valid data (at least one non-zero value)
    final hasValidData = widget.series.dataPoints.any((point) => 
      point.value != null && point.value! > 0
    );

    if (!hasValidData) {
      return _buildEmptyState();
    }

    final maxValue = _getMaxValue();
    final minValue = _getMinValue();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
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
          // Summary Metrics (if provided)
          if (widget.summaryMetrics != null && widget.summaryMetrics!.isNotEmpty) ...[
            _buildSummaryMetrics(),
            SizedBox(height: 12.h),
          ],
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
              // For weight chart: plus icon to add/update weight; otherwise Week/Month toggle
              if (widget.chartType == ChartType.weight && widget.onAddTap != null)
                IconButton(
                  onPressed: widget.onAddTap,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: widget.series.color,
                    size: 28.sp,
                  ),
                  tooltip: 'Add or update weight',
                )
              else if (widget.chartType != ChartType.weight)
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
          // Chart (bar or line)
          SizedBox(
            height: 190.h,
            child: widget.useBarChart
                ? BarChart(
                    _buildBarChartData(maxValue, minValue, hasValidData, highContrast),
                    swapAnimationDuration: const Duration(milliseconds: 250),
                  )
                : LineChart(
                    _buildChartData(maxValue, minValue, hasValidData, highContrast),
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

  LineChartData _buildChartData(double maxValue, double minValue, bool hasValidData, bool highContrast) {
    final dataPoints = _isWeekly 
        ? _getWeeklyDataPoints() 
        : _getMonthlyDataPoints();
    
    // Get the interval and fixed min/max based on chart type
    final interval = _getYAxisInterval();
    final adjustedMin = _getMinValue();
    final adjustedMax = _getMaxValue();
    
    return LineChartData(
      gridData: FlGridData(
        show: hasValidData, // Only show grid when we have valid data
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          final opacity = highContrast ? 0.3 : 0.1;
          return FlLine(
            color: Colors.white.withOpacity(opacity),
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
              // Weight chart with 15 days: show only 6 X-axis labels at indices 0, 2, 5, 8, 11, 14
              const weightChartLabelIndices = [0, 2, 5, 8, 11, 14];
              if (widget.chartType == ChartType.weight &&
                  dataPoints.length == 15 &&
                  !weightChartLabelIndices.contains(index)) {
                return const SizedBox.shrink();
              }
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
      lineBarsData: _buildLineBarsData(dataPoints),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final pointIndex = touchedSpot.x.toInt();
              final dataPoints = _isWeekly 
                  ? _getWeeklyDataPoints() 
                  : _getMonthlyDataPoints();
              
              if (pointIndex >= 0 && pointIndex < dataPoints.length) {
                final point = dataPoints[pointIndex];
                final unit = _getUnit();
                final date = point.label;
                
                // Build tooltip with better formatting
                String tooltipText = '${widget.series.name}\n${_formatYAxisValue(touchedSpot.y)} $unit\n$date';
                
                // Add anomaly warning if applicable
                if (point.isAnomaly) {
                  tooltipText = '⚠️ $tooltipText\n\nUnusual value detected';
                }
                
                // Add comparison if previous day exists
                if (pointIndex > 0 && dataPoints[pointIndex - 1].value != null) {
                  final prevValue = dataPoints[pointIndex - 1].value!;
                  final diff = touchedSpot.y - prevValue;
                  final trend = diff > 0 ? '↗' : (diff < 0 ? '↘' : '→');
                  tooltipText += '\nvs Yesterday: $trend ${diff.abs().toStringAsFixed(1)} $unit';
                }
                
                return LineTooltipItem(
                  tooltipText,
                  GoogleFonts.ubuntu(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: point.isAnomaly ? Colors.orange : widget.series.color,
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

  BarChartData _buildBarChartData(double maxValue, double minValue, bool hasValidData, bool highContrast) {
    final dataPoints = _getWeeklyDataPoints();
    final interval = _getYAxisInterval();
    final adjustedMin = _getMinValue();
    final adjustedMax = _getMaxValue();

    final barGroups = dataPoints.asMap().entries.map((entry) {
      final i = entry.key;
      final point = entry.value;
      final value = (point.value != null && point.value! > 0) ? point.value! : 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value.clamp(adjustedMin, adjustedMax),
            color: widget.series.color,
            width: 12.w,
            borderRadius: BorderRadius.circular(4.r),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: adjustedMax,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ],
        showingTooltipIndicators: _touchedIndex == i ? [0] : [],
      );
    }).toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: adjustedMax,
      minY: adjustedMin,
      barGroups: barGroups,
      gridData: FlGridData(
        show: hasValidData,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(highContrast ? 0.3 : 0.1),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (groupIndex >= 0 && groupIndex < dataPoints.length) {
              final point = dataPoints[groupIndex];
              final unit = _getUnit();
              return BarTooltipItem(
                '${widget.series.name}\n${_formatYAxisValue(rod.toY)} $unit\n${point.label}',
                GoogleFonts.ubuntu(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: widget.series.color,
                ),
              );
            }
            return null;
          },
          tooltipPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          tooltipMargin: 8,
        ),
        touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
          if (!event.isInterestedForInteractions || response == null) {
            setState(() => _touchedIndex = null);
            return;
          }
          setState(() {
            _touchedIndex = response.spot?.touchedBarGroupIndex;
          });
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
        case ChartType.heartRate:
          value = 60 + (index % 6) * 6.0;
          break;
        case ChartType.steps:
          value = 5000 + (index % 6) * 2000.0;
          break;
      }
      
      return ChartDataPoint(
        value: value,
        label: month,
      );
    }).toList();
  }

  double _getMaxValue() {
    // For weight, use dynamic maximum based on data
    if (widget.chartType == ChartType.weight) {
      final validValues = widget.series.dataPoints
          .where((p) => p.value != null && p.value! > 0)
          .map((p) => p.value!)
          .toList();
      
      if (validValues.isNotEmpty) {
        final maxData = validValues.reduce((a, b) => a > b ? a : b);
        // Use maximum + 5 kg buffer, but cap at 200 kg
        return (maxData + 5).clamp(0.0, 200.0);
      }
    }
    
    // Fixed Y-axis ranges for other graphs
    switch (widget.chartType) {
      case ChartType.weight:
        return 200.0; // Fallback
      case ChartType.calories:
        // Dynamic for calories if all data < 2000
        final validValues = widget.series.dataPoints
            .where((p) => p.value != null && p.value! > 0)
            .map((p) => p.value!)
            .toList();
        if (validValues.isNotEmpty) {
          final maxData = validValues.reduce((a, b) => a > b ? a : b);
          if (maxData < 2000) {
            return 2500.0; // Adjusted max with 250 kcal intervals
          }
        }
        return 4000.0;
      case ChartType.heartRate:
        // Dynamic for heart rate if all data < 100 bpm
        final validValues = widget.series.dataPoints
            .where((p) => p.value != null && p.value! > 0)
            .map((p) => p.value!)
            .toList();
        if (validValues.isNotEmpty) {
          final maxData = validValues.reduce((a, b) => a > b ? a : b);
          if (maxData < 100) {
            return 120.0; // Adjusted max with 10 bpm intervals
          }
        }
        return 200.0;
      case ChartType.steps:
        final validValues = widget.series.dataPoints
            .where((p) => p.value != null && p.value! > 0)
            .map((p) => p.value!)
            .toList();
        if (validValues.isNotEmpty) {
          final maxData = validValues.reduce((a, b) => a > b ? a : b);
          return (maxData + 2000).clamp(2000.0, 50000.0);
        }
        return 15000.0;
    }
  }

  double _getMinValue() {
    // For weight, use dynamic minimum (never 0 kg)
    if (widget.chartType == ChartType.weight) {
      final validValues = widget.series.dataPoints
          .where((p) => p.value != null && p.value! > 0)
          .map((p) => p.value!)
          .toList();
      
      if (validValues.isNotEmpty) {
        final minData = validValues.reduce((a, b) => a < b ? a : b);
        // Use minimum - 5 kg buffer, but never below 40 kg
        return (minData - 5).clamp(40.0, double.infinity);
      }
      // Default to 40 kg if no data (reasonable adult minimum)
      return 40.0;
    }
    if (widget.chartType == ChartType.steps) return 0.0;
    return 0.0;
  }

  double _getYAxisInterval() {
    final maxValue = _getMaxValue();
    
    switch (widget.chartType) {
      case ChartType.weight:
        // Use 10 kg intervals if range is small, otherwise 20 kg
        final range = maxValue - _getMinValue();
        return range < 20 ? 10.0 : 20.0;
      case ChartType.calories:
        // Use 250 kcal intervals if max < 2500, otherwise 500 kcal
        return maxValue < 2500 ? 250.0 : 500.0;
      case ChartType.heartRate:
        return maxValue < 120 ? 10.0 : 20.0;
      case ChartType.steps:
        return maxValue < 20000 ? 2000.0 : 5000.0;
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
      case ChartType.heartRate:
        return value.toInt().toString();
      case ChartType.steps:
        return value.toInt().toString();
    }
  }

  String _getUnit() {
    switch (widget.chartType) {
      case ChartType.weight:
        return 'kg';
      case ChartType.calories:
        return 'kcal';
      case ChartType.heartRate:
        return 'bpm';
      case ChartType.steps:
        return 'steps';
    }
  }

  List<LineChartBarData> _buildLineBarsData(List<ChartDataPoint> dataPoints) {
    final spots = <FlSpot>[];
    final missingIndices = <int>[];
    
    // Build spots, handling missing data
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      if (point.value != null && point.value! > 0) {
        spots.add(FlSpot(i.toDouble(), point.value!));
      } else {
        missingIndices.add(i);
      }
    }

    // Main line (solid for valid data, dashed for gaps)
    return [
      LineChartBarData(
        spots: spots,
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
      // Anomaly points (if any)
      if (dataPoints.any((p) => p.isAnomaly))
        LineChartBarData(
          spots: dataPoints.asMap().entries
              .where((entry) => entry.value.isAnomaly && entry.value.value != null)
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value!))
              .toList(),
          isCurved: false,
          color: Colors.orange,
          barWidth: 0,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: Colors.orange,
                strokeWidth: 3,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
    ];
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;
    String secondaryMessage;

    switch (widget.chartType) {
      case ChartType.heartRate:
        icon = Icons.favorite;
        message = 'No heart rate data yet';
        secondaryMessage = 'Heart rate syncs from wearables (e.g. Wear OS, Fitbit, Garmin) or workout apps that write to Google Fit. Connect a device or log a workout to see data here.';
        break;
      case ChartType.calories:
        icon = Icons.local_fire_department;
        message = 'No calorie data yet';
        secondaryMessage = 'Sync with Google Fit or log activities to see your burn.';
        break;
      case ChartType.weight:
        icon = Icons.monitor_weight;
        message = 'No weight data yet';
        secondaryMessage = 'Add your weight to start tracking your progress.';
        break;
      case ChartType.steps:
        icon = Icons.directions_walk;
        message = 'No steps data yet';
        secondaryMessage = 'Sync with Google Fit to see your daily steps.';
        break;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48.sp,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: GoogleFonts.ubuntu(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            secondaryMessage,
            style: GoogleFonts.ubuntu(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
          SizedBox(height: 15.h),
          SizedBox(
            height: 190.h,
            child: ShimmerLoading(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
          SizedBox(height: 15.h),
          SizedBox(
            height: 190.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.errorMessage ?? 'Failed to load data',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.onRetry != null) ...[
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: widget.onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.series.color,
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    if (widget.summaryMetrics == null || widget.summaryMetrics!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: widget.summaryMetrics!.entries.map((entry) {
          return Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: GoogleFonts.ubuntu(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  entry.value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


