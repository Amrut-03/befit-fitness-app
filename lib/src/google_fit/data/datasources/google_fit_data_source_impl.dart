import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';

/// Implementation of Google Fit data source using the health package
class GoogleFitDataSourceImpl implements GoogleFitDataSource {
  final Health health;

  // Define the types of health data we want to access
  static const List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  GoogleFitDataSourceImpl({required this.health});

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await health.hasPermissions(types);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Debug method to fetch and display ALL available health data
  Future<void> debugAllHealthData() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔍 HEALTH CONNECT DEBUG - ALL AVAILABLE DATA');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      
      debugPrint('📅 Today: $now');
      debugPrint('⏰ Today Range: $startOfDay to $endOfDay');
      debugPrint('⏰ Week Range: $weekAgo to $now');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Check permissions for all types
      debugPrint('🔐 Checking permissions...');
      for (var type in types) {
        try {
          final hasPerm = await health.hasPermissions([type]);
          debugPrint('   $type: ${hasPerm ?? false ? "✅ Granted" : "❌ Denied"}');
        } catch (e) {
          debugPrint('   $type: ❌ Error - $e');
        }
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 Fetching all data types...');
      
      // Fetch all data types
      for (var type in types) {
        try {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('📈 Fetching: $type');
          
          final data = await health.getHealthDataFromTypes(
            types: [type],
            startTime: weekAgo,
            endTime: now,
          );
          
          debugPrint('   Found ${data.length} data points');
          
          if (data.isNotEmpty) {
            // Show first 5 entries
            final entriesToShow = data.length > 5 ? 5 : data.length;
            for (int i = 0; i < entriesToShow; i++) {
              final entry = data[i];
              debugPrint('   Entry ${i + 1}:');
              debugPrint('      Value: ${entry.value}');
              debugPrint('      Date: ${entry.dateFrom} to ${entry.dateTo}');
              debugPrint('      Source: ${entry.sourceName}');
              debugPrint('      Platform: ${entry.sourcePlatform}');
            }
            if (data.length > 5) {
              debugPrint('   ... and ${data.length - 5} more entries');
            }
          } else {
            debugPrint('   ⚠️  No data found');
          }
        } catch (e) {
          debugPrint('   ❌ Error fetching $type: $e');
        }
      }
      
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('✅ Debug complete!');
      debugPrint('═══════════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in debugAllHealthData: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔐 HEALTH CONNECT DEBUG - REQUESTING PERMISSIONS');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📝 Requesting permissions for data types:');
      for (var type in types) {
        debugPrint('   - $type');
      }
      
      final result = await health.requestAuthorization(types);
      
      debugPrint('✅ Permission Request Result: $result');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR requesting permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔐 HEALTH CONNECT DEBUG - PERMISSION CHECK');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔍 Checking permissions for data types:');
      for (var type in types) {
        debugPrint('   - $type');
      }
      
      final result = await health.hasPermissions(types);
      final hasPerms = result ?? false;
      
      debugPrint('✅ Permission Status: $hasPerms');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      return hasPerms;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR checking permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<int?> getSteps(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🏃 HEALTH CONNECT DEBUG - STEPS DATA');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📅 Date: $date');
      debugPrint('⏰ Time Range: $startOfDay to $endOfDay');
      debugPrint('🔍 Fetching steps data...');

      final steps = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      debugPrint('📊 Total data points retrieved: ${steps.length}');

      if (steps.isEmpty) {
        debugPrint('⚠️  No steps data found for this date');
        debugPrint('═══════════════════════════════════════════════════════════');
        return null;
      }

      int totalSteps = 0;
      int index = 0;
      
      for (var step in steps) {
        index++;
        final value = (step.value as NumericHealthValue).numericValue.toInt();
        totalSteps += value;
        
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📈 Step Entry #$index:');
        debugPrint('   Value: $value steps');
        debugPrint('   UUID: ${step.uuid}');
        debugPrint('   Type: ${step.type}');
        debugPrint('   Unit: ${step.unit}');
        debugPrint('   Date From: ${step.dateFrom}');
        debugPrint('   Date To: ${step.dateTo}');
        debugPrint('   Source Platform: ${step.sourcePlatform}');
        debugPrint('   Source Device ID: ${step.sourceDeviceId}');
        debugPrint('   Source ID: ${step.sourceId}');
        debugPrint('   Source Name: ${step.sourceName}');
        debugPrint('   Recording Method: ${step.recordingMethod}');
        if (step.workoutSummary != null) {
          debugPrint('   Workout Summary: ${step.workoutSummary}');
        }
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ Total Steps: $totalSteps');
      debugPrint('═══════════════════════════════════════════════════════════');

      return totalSteps;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching steps: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<int> getStepsInRange(DateTime startDate, DateTime endDate) async {
    try {
      final steps = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startDate,
        endTime: endDate,
      );

      int totalSteps = 0;
      for (var step in steps) {
        totalSteps += (step.value as NumericHealthValue).numericValue.toInt();
      }

      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<double?> getDistance(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📏 HEALTH CONNECT DEBUG - DISTANCE DATA');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📅 Date: $date');
      debugPrint('⏰ Time Range: $startOfDay to $endOfDay');
      debugPrint('🔍 Fetching distance data...');

      final distance = await health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_DELTA],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      debugPrint('📊 Total data points retrieved: ${distance.length}');

      if (distance.isEmpty) {
        debugPrint('⚠️  No distance data found for this date');
        debugPrint('═══════════════════════════════════════════════════════════');
        return null;
      }

      double totalDistance = 0;
      int index = 0;
      
      for (var dist in distance) {
        index++;
        final value = (dist.value as NumericHealthValue).numericValue.toDouble();
        totalDistance += value;
        
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📏 Distance Entry #$index:');
        debugPrint('   Value: ${value.toStringAsFixed(2)} meters');
        debugPrint('   UUID: ${dist.uuid}');
        debugPrint('   Type: ${dist.type}');
        debugPrint('   Unit: ${dist.unit}');
        debugPrint('   Date From: ${dist.dateFrom}');
        debugPrint('   Date To: ${dist.dateTo}');
        debugPrint('   Source Platform: ${dist.sourcePlatform}');
        debugPrint('   Source Device ID: ${dist.sourceDeviceId}');
        debugPrint('   Source ID: ${dist.sourceId}');
        debugPrint('   Source Name: ${dist.sourceName}');
        debugPrint('   Recording Method: ${dist.recordingMethod}');
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ Total Distance: ${totalDistance.toStringAsFixed(2)} meters');
      debugPrint('═══════════════════════════════════════════════════════════');

      return totalDistance; // in meters
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching distance: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<double> getDistanceInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final distance = await health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_DELTA],
        startTime: startDate,
        endTime: endDate,
      );

      double totalDistance = 0;
      for (var dist in distance) {
        totalDistance +=
            (dist.value as NumericHealthValue).numericValue.toDouble();
      }

      return totalDistance; // in meters
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<double?> getCalories(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🔥 HEALTH CONNECT DEBUG - CALORIES DATA');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📅 Date: $date');
      debugPrint('⏰ Time Range: $startOfDay to $endOfDay');
      debugPrint('🔍 Fetching calories data...');

      final calories = await health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      debugPrint('📊 Total data points retrieved: ${calories.length}');

      if (calories.isEmpty) {
        debugPrint('⚠️  No calories data found for this date');
        debugPrint('═══════════════════════════════════════════════════════════');
        return null;
      }

      double totalCalories = 0;
      int index = 0;
      
      for (var cal in calories) {
        index++;
        final value = (cal.value as NumericHealthValue).numericValue.toDouble();
        totalCalories += value;
        
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🔥 Calorie Entry #$index:');
        debugPrint('   Value: $value kcal');
        debugPrint('   UUID: ${cal.uuid}');
        debugPrint('   Type: ${cal.type}');
        debugPrint('   Unit: ${cal.unit}');
        debugPrint('   Date From: ${cal.dateFrom}');
        debugPrint('   Date To: ${cal.dateTo}');
        debugPrint('   Source Platform: ${cal.sourcePlatform}');
        debugPrint('   Source Device ID: ${cal.sourceDeviceId}');
        debugPrint('   Source ID: ${cal.sourceId}');
        debugPrint('   Source Name: ${cal.sourceName}');
        debugPrint('   Recording Method: ${cal.recordingMethod}');
        if (cal.workoutSummary != null) {
          debugPrint('   Workout Summary: ${cal.workoutSummary}');
        }
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ Total Calories: $totalCalories kcal');
      debugPrint('═══════════════════════════════════════════════════════════');

      return totalCalories; // in kcal
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching calories: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<double> getCaloriesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final calories = await health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startDate,
        endTime: endDate,
      );

      double totalCalories = 0;
      for (var cal in calories) {
        totalCalories +=
            (cal.value as NumericHealthValue).numericValue.toDouble();
      }

      return totalCalories; // in kcal
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<double?> getHeartRate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('❤️  HEALTH CONNECT DEBUG - HEART RATE DATA');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📅 Date: $date');
      debugPrint('⏰ Time Range: $startOfDay to $endOfDay');
      debugPrint('🔍 Fetching heart rate data...');

      final heartRate = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      debugPrint('📊 Total data points retrieved: ${heartRate.length}');

      if (heartRate.isEmpty) {
        debugPrint('⚠️  No heart rate data found for this date');
        debugPrint('═══════════════════════════════════════════════════════════');
        return null;
      }

      // Get the most recent heart rate reading
      heartRate.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = heartRate.first;
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❤️  All Heart Rate Readings:');
      int index = 0;
      for (var hr in heartRate) {
        index++;
        final value = (hr.value as NumericHealthValue).numericValue.toDouble();
        debugPrint('   Reading #$index: $value bpm');
        debugPrint('      UUID: ${hr.uuid}');
        debugPrint('      Date From: ${hr.dateFrom}');
        debugPrint('      Date To: ${hr.dateTo}');
        debugPrint('      Source: ${hr.sourceName}');
        if (hr == latest) {
          debugPrint('      ⭐ (Most Recent)');
        }
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ Latest Heart Rate: ${(latest.value as NumericHealthValue).numericValue.toDouble()} bpm');
      debugPrint('═══════════════════════════════════════════════════════════');

      return (latest.value as NumericHealthValue).numericValue.toDouble();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching heart rate: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<double?> getWeight() async {
    try {
      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 365)); // Last year

      final weight = await health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: past,
        endTime: now,
      );

      if (weight.isEmpty) return null;

      // Get the most recent weight reading
      weight.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = weight.first;
      return (latest.value as NumericHealthValue).numericValue.toDouble();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<double?> getHeight() async {
    try {
      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 365)); // Last year

      final height = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: past,
        endTime: now,
      );

      if (height.isEmpty) return null;

      // Get the most recent height reading
      height.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = height.first;
      return (latest.value as NumericHealthValue).numericValue.toDouble();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<FitnessData> getFitnessDataForDate(DateTime date) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📊 HEALTH CONNECT DEBUG - COMPLETE FITNESS DATA');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📅 Fetching all fitness data for: $date');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final steps = await getSteps(date);
    final distance = await getDistance(date);
    final calories = await getCalories(date);
    final heartRate = await getHeartRate(date);

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📋 SUMMARY - All Fitness Data for $date:');
    debugPrint('   Steps: ${steps ?? 'N/A'}');
    debugPrint('   Distance: ${distance != null ? "${distance.toStringAsFixed(2)} meters" : 'N/A'}');
    debugPrint('   Calories: ${calories != null ? "${calories.toStringAsFixed(2)} kcal" : 'N/A'}');
    debugPrint('   Heart Rate: ${heartRate != null ? "${heartRate.toStringAsFixed(0)} bpm" : 'N/A'}');
    debugPrint('═══════════════════════════════════════════════════════════');

    return FitnessData(
      steps: steps,
      distance: distance,
      calories: calories,
      heartRate: heartRate,
      date: date,
    );
  }

  @override
  Future<AggregatedFitnessData> getAggregatedData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final totalSteps = await getStepsInRange(startDate, endDate);
    final totalDistance = await getDistanceInRange(startDate, endDate);
    final totalCalories = await getCaloriesInRange(startDate, endDate);

    // Calculate average heart rate for the range
    double? averageHeartRate;
    try {
      final heartRates = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startDate,
        endTime: endDate,
      );

      if (heartRates.isNotEmpty) {
        double sum = 0;
        for (var hr in heartRates) {
          sum += (hr.value as NumericHealthValue).numericValue.toDouble();
        }
        averageHeartRate = sum / heartRates.length;
      }
    } catch (e) {
      // Ignore errors for average heart rate
    }

    return AggregatedFitnessData(
      totalSteps: totalSteps,
      totalDistance: totalDistance,
      totalCalories: totalCalories,
      averageHeartRate: averageHeartRate,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> writeSteps(int steps, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(hours: 1));

      await health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        unit: HealthDataUnit.COUNT,
        startTime: startOfDay,
        endTime: endOfDay,
      );
    } catch (e) {
      throw Exception('Failed to write steps: $e');
    }
  }

  @override
  Future<void> writeHeartRate(double heartRate, DateTime date) async {
    try {
      final endTime = date.add(const Duration(minutes: 1));

      await health.writeHealthData(
        value: heartRate,
        type: HealthDataType.HEART_RATE,
        unit: HealthDataUnit.BEATS_PER_MINUTE,
        startTime: date,
        endTime: endTime,
      );
    } catch (e) {
      throw Exception('Failed to write heart rate: $e');
    }
  }

  @override
  Future<void> writeWeight(double weight, DateTime date) async {
    try {
      final endTime = date.add(const Duration(minutes: 1));

      await health.writeHealthData(
        value: weight,
        type: HealthDataType.WEIGHT,
        unit: HealthDataUnit.KILOGRAM,
        startTime: date,
        endTime: endTime,
      );
    } catch (e) {
      throw Exception('Failed to write weight: $e');
    }
  }
}

