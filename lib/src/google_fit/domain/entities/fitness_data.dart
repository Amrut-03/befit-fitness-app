import 'package:equatable/equatable.dart';

/// Entity representing fitness data from Google Fit
class FitnessData extends Equatable {
  final int? steps;
  final double? distance; // in meters
  final double? calories; // in kcal
  final double? heartRate; // in bpm
  final double? weight; // in kg
  final double? height; // in meters
  final DateTime? date;

  const FitnessData({
    this.steps,
    this.distance,
    this.calories,
    this.heartRate,
    this.weight,
    this.height,
    this.date,
  });

  @override
  List<Object?> get props => [
        steps,
        distance,
        calories,
        heartRate,
        weight,
        height,
        date,
      ];

  FitnessData copyWith({
    int? steps,
    double? distance,
    double? calories,
    double? heartRate,
    double? weight,
    double? height,
    DateTime? date,
  }) {
    return FitnessData(
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      heartRate: heartRate ?? this.heartRate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      date: date ?? this.date,
    );
  }
}

/// Entity representing aggregated fitness data for a date range
class AggregatedFitnessData extends Equatable {
  final int totalSteps;
  final double totalDistance; // in meters
  final double totalCalories; // in kcal
  final double? averageHeartRate; // in bpm
  final DateTime startDate;
  final DateTime endDate;

  const AggregatedFitnessData({
    required this.totalSteps,
    required this.totalDistance,
    required this.totalCalories,
    this.averageHeartRate,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
        totalSteps,
        totalDistance,
        totalCalories,
        averageHeartRate,
        startDate,
        endDate,
      ];
}

