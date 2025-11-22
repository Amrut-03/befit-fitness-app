import 'package:equatable/equatable.dart';

/// Entity representing user health metrics
class HealthMetrics extends Equatable {
  final double? bmi;
  final int? bmr;
  final int? hrc;
  final double? overallHealthPercentage;

  const HealthMetrics({
    this.bmi,
    this.bmr,
    this.hrc,
    this.overallHealthPercentage,
  });

  @override
  List<Object?> get props => [bmi, bmr, hrc, overallHealthPercentage];

  /// Calculate health percentages for pie chart
  Map<String, double> calculateHealthPercentages() {
    const double maxBmi = 25.0;
    const double maxBmr = 100.0;
    const double maxHrc = 180.0;

    double bmiPercentage = ((bmi ?? 0) / maxBmi) * 100;
    double bmrPercentage = ((bmr ?? 0) / maxBmr) * 100;
    double hrcPercentage = ((hrc ?? 0) / maxHrc) * 100;

    bmiPercentage = bmiPercentage.clamp(0, 100);
    bmrPercentage = bmrPercentage.clamp(0, 100);
    hrcPercentage = hrcPercentage.clamp(0, 100);

    double total = bmiPercentage + bmrPercentage + hrcPercentage;

    if (total > 100) {
      bmiPercentage = (bmiPercentage / total) * 100;
      bmrPercentage = (bmrPercentage / total) * 100;
      hrcPercentage = (hrcPercentage / total) * 100;
    }

    double remainingPercentage =
        100 - (bmiPercentage + bmrPercentage + hrcPercentage);

    return {
      'BMI': bmiPercentage,
      'BMR': bmrPercentage,
      'HRC': hrcPercentage,
      'Remaining': remainingPercentage,
    };
  }
}

