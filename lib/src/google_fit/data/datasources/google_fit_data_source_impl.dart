import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_rest_client.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';

/// Implementation of Google Fit data source using REST API
class GoogleFitDataSourceImpl implements GoogleFitDataSource {
  final GoogleFitRestClient _restClient;
  final GoogleSignIn _googleSignIn;

  // Google Fit data type names
  static const String _dataTypeSteps = 'com.google.step_count.delta';
  static const String _dataTypeDistance = 'com.google.distance.delta';
  static const String _dataTypeCalories = 'com.google.calories.expended';
  static const String _dataTypeHeartRate = 'com.google.heart_rate.bpm';
  static const String _dataTypeWeight = 'com.google.weight';
  static const String _dataTypeHeight = 'com.google.height';
  static const String _dataTypeActiveMinutes = 'com.google.active_minutes';

  GoogleFitDataSourceImpl({
    required GoogleSignIn googleSignIn,
    GoogleFitRestClient? restClient,
  })  : _googleSignIn = googleSignIn,
        _restClient = restClient ?? GoogleFitRestClient(googleSignIn: googleSignIn);

  @override
  Future<bool> isAvailable() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      debugPrint('GoogleFitDataSourceImpl: Error checking availability: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      debugPrint('GoogleFitDataSource: Error requesting permissions: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      debugPrint('GoogleFitDataSource: Error checking permissions: $e');
      return false;
    }
  }

  /// Extract value from aggregated bucket
  int _extractIntValue(Map<String, dynamic> bucket) {
    try {
      final dataset = bucket['dataset'] as List<dynamic>?;
      if (dataset == null || dataset.isEmpty) return 0;

      int total = 0;
      for (var data in dataset) {
        final point = data['point'] as List<dynamic>?;
        if (point == null || point.isEmpty) continue;

        for (var p in point) {
          final value = p['value'] as List<dynamic>?;
          if (value == null || value.isEmpty) continue;

          for (var v in value) {
            if (v['intVal'] != null) {
              total += (v['intVal'] as num).toInt();
            }
          }
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error extracting int value: $e');
      return 0;
    }
  }

  /// Extract float value from aggregated bucket
  double _extractFloatValue(Map<String, dynamic> bucket) {
    try {
      final dataset = bucket['dataset'] as List<dynamic>?;
      if (dataset == null || dataset.isEmpty) return 0.0;

      double total = 0.0;
      for (var data in dataset) {
        final point = data['point'] as List<dynamic>?;
        if (point == null || point.isEmpty) continue;

        for (var p in point) {
          final value = p['value'] as List<dynamic>?;
          if (value == null || value.isEmpty) continue;

          for (var v in value) {
            if (v['fpVal'] != null) {
              total += (v['fpVal'] as num).toDouble();
            } else if (v['intVal'] != null) {
              total += (v['intVal'] as num).toDouble();
            }
          }
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error extracting float value: $e');
      return 0.0;
    }
  }

  @override
  Future<int?> getSteps(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeSteps,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      final bucket = data['bucket'] as List<dynamic>?;
      if (bucket == null || bucket.isEmpty) return null;

      int totalSteps = 0;
      for (var b in bucket) {
        totalSteps += _extractIntValue(b as Map<String, dynamic>);
      }

      return totalSteps;
    } catch (e) {
      debugPrint('GoogleFitDataSource: Error fetching steps: $e');
      return null;
    }
  }

  @override
  Future<int> getStepsInRange(DateTime startDate, DateTime endDate) async {
    try {
      final data = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeSteps,
        startTime: startDate,
        endTime: endDate,
      );

      final bucket = data['bucket'] as List<dynamic>?;
      if (bucket == null || bucket.isEmpty) return 0;

      int totalSteps = 0;
      for (var b in bucket) {
        totalSteps += _extractIntValue(b as Map<String, dynamic>);
      }

      return totalSteps;
    } catch (e) {
      debugPrint('Error fetching steps in range: $e');
      return 0;
    }
  }

  @override
  Future<double?> getDistance(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeDistance,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      final bucket = data['bucket'] as List<dynamic>?;
      if (bucket == null || bucket.isEmpty) return null;

      double totalDistance = 0.0;
      for (var b in bucket) {
        totalDistance += _extractFloatValue(b as Map<String, dynamic>);
      }

      return totalDistance;
    } catch (e) {
      debugPrint('GoogleFitDataSource: Error fetching distance: $e');
      return null;
    }
  }

  @override
  Future<double> getDistanceInRange(DateTime startDate, DateTime endDate) async {
    try {
      final data = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeDistance,
        startTime: startDate,
        endTime: endDate,
      );

      final bucket = data['bucket'] as List<dynamic>?;
      if (bucket == null || bucket.isEmpty) return 0.0;

      double totalDistance = 0.0;
      for (var b in bucket) {
        totalDistance += _extractFloatValue(b as Map<String, dynamic>);
      }

      return totalDistance; // in meters
    } catch (e) {
      debugPrint('Error fetching distance in range: $e');
      return 0.0;
    }
  }

  @override
  Future<double?> getCalories(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeCalories,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      final bucket = data['bucket'] as List<dynamic>?;
      if (bucket == null || bucket.isEmpty) return null;

      double totalCalories = 0.0;
      for (var b in bucket) {
        totalCalories += _extractFloatValue(b as Map<String, dynamic>);
      }

      return totalCalories;
    } catch (e) {
      debugPrint('GoogleFitDataSource: Error fetching calories: $e');
      return null;
    }
  }

  @override
  Future<double> getCaloriesInRange(DateTime startDate, DateTime endDate) async {
    try {
      final data = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeCalories,
        startTime: startDate,
        endTime: endDate,
      );

      final bucket = data['bucket'] as List<dynamic>?;
      if (bucket == null || bucket.isEmpty) return 0.0;

      double totalCalories = 0.0;
      for (var b in bucket) {
        totalCalories += _extractFloatValue(b as Map<String, dynamic>);
      }

      return totalCalories; // in kcal
    } catch (e) {
      debugPrint('Error fetching calories in range: $e');
      return 0.0;
    }
  }

  @override
  Future<double?> getHeartRate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final dataSources = await _restClient.getDataSources(dataTypeName: _dataTypeHeartRate);
      if (dataSources.isEmpty) return null;

      double? latestHeartRate;
      DateTime? latestTime;

      for (var ds in dataSources) {
        try {
          final dataSourceId = ds['dataStreamId'] ?? ds['dataSourceId'];
          if (dataSourceId == null) continue;
          
          final dataset = await _restClient.getDataset(
            dataSourceId: dataSourceId as String,
            startTime: startOfDay,
            endTime: endOfDay,
          );

          final point = dataset['point'] as List<dynamic>?;
          if (point == null || point.isEmpty) continue;

          for (var p in point) {
            final startTimeNanos = p['startTimeNanos'] as String?;
            final value = p['value'] as List<dynamic>?;
            if (value == null || value.isEmpty) continue;

            for (var v in value) {
              double? hr;
              if (v['fpVal'] != null) {
                hr = (v['fpVal'] as num).toDouble();
              } else if (v['intVal'] != null) {
                hr = (v['intVal'] as num).toDouble();
              }

              if (hr != null && startTimeNanos != null) {
                final time = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(startTimeNanos) ~/ 1000000,
                );
                
                if (latestTime == null || time.isAfter(latestTime)) {
                  latestTime = time;
                  latestHeartRate = hr;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return latestHeartRate;
    } catch (e) {
      debugPrint('GoogleFitDataSource: Error fetching heart rate: $e');
      return null;
    }
  }

  @override
  Future<double?> getWeight() async {
    try {
      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 365)); // Last year

      final dataSources = await _restClient.getDataSources(dataTypeName: _dataTypeWeight);
      if (dataSources.isEmpty) return null;

      double? latestWeight;
      DateTime? latestTime;

      for (var ds in dataSources) {
        try {
          final dataSourceId = ds['dataStreamId'] ?? ds['dataSourceId'];
          if (dataSourceId == null) continue;
          
          final dataset = await _restClient.getDataset(
            dataSourceId: dataSourceId as String,
            startTime: past,
            endTime: now,
          );

          final point = dataset['point'] as List<dynamic>?;
          if (point == null || point.isEmpty) continue;

          for (var p in point) {
            final startTimeNanos = p['startTimeNanos'] as String?;
            final value = p['value'] as List<dynamic>?;
            if (value == null || value.isEmpty) continue;

            for (var v in value) {
              double? weight;
              if (v['fpVal'] != null) {
                weight = (v['fpVal'] as num).toDouble();
              } else if (v['intVal'] != null) {
                weight = (v['intVal'] as num).toDouble();
              }

              if (weight != null && startTimeNanos != null) {
                final time = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(startTimeNanos) ~/ 1000000,
                );
                if (latestTime == null || time.isAfter(latestTime)) {
                  latestTime = time;
                  latestWeight = weight;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return latestWeight;
    } catch (e) {
      debugPrint('Error fetching weight: $e');
      return null;
    }
  }

  @override
  Future<double?> getHeight() async {
    try {
      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 365)); // Last year

      final dataSources = await _restClient.getDataSources(dataTypeName: _dataTypeHeight);
      if (dataSources.isEmpty) return null;

      double? latestHeight;
      DateTime? latestTime;

      for (var ds in dataSources) {
        try {
          final dataSourceId = ds['dataStreamId'] ?? ds['dataSourceId'];
          if (dataSourceId == null) continue;
          
          final dataset = await _restClient.getDataset(
            dataSourceId: dataSourceId as String,
            startTime: past,
            endTime: now,
          );

          final point = dataset['point'] as List<dynamic>?;
          if (point == null || point.isEmpty) continue;

          for (var p in point) {
            final startTimeNanos = p['startTimeNanos'] as String?;
            final value = p['value'] as List<dynamic>?;
            if (value == null || value.isEmpty) continue;

            for (var v in value) {
              double? height;
              if (v['fpVal'] != null) {
                height = (v['fpVal'] as num).toDouble();
              } else if (v['intVal'] != null) {
                height = (v['intVal'] as num).toDouble();
              }

              if (height != null && startTimeNanos != null) {
                final time = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(startTimeNanos) ~/ 1000000,
                );
                if (latestTime == null || time.isAfter(latestTime)) {
                  latestTime = time;
                  latestHeight = height;
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return latestHeight;
    } catch (e) {
      debugPrint('Error fetching height: $e');
      return null;
    }
  }

  @override
  Future<FitnessData> getFitnessDataForDate(DateTime date) async {
    final steps = await getSteps(date);
    final distance = await getDistance(date);
    final calories = await getCalories(date);
    final heartRate = await getHeartRate(date);

    int? moveMinutes;
    try {
      final activeMinutesData = await _restClient.getAggregatedData(
        dataTypeName: _dataTypeActiveMinutes,
        startTime: DateTime(date.year, date.month, date.day),
        endTime: DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
      );
      
      final activeBuckets = activeMinutesData['bucket'] as List<dynamic>?;
      if (activeBuckets != null && activeBuckets.isNotEmpty) {
        int totalMinutes = 0;
        for (var bucket in activeBuckets) {
          totalMinutes += _extractIntValue(bucket as Map<String, dynamic>);
        }
        moveMinutes = totalMinutes;
      }
    } catch (e) {
      try {
        final activityData = await _restClient.getAggregatedData(
          dataTypeName: 'com.google.activity.segment',
          startTime: DateTime(date.year, date.month, date.day),
          endTime: DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
        );
        
        final activityBuckets = activityData['bucket'] as List<dynamic>?;
        if (activityBuckets != null && activityBuckets.isNotEmpty) {
          int totalMinutes = 0;
          for (var bucket in activityBuckets) {
            final startTime = bucket['startTimeMillis'] as String?;
            final endTime = bucket['endTimeMillis'] as String?;
            if (startTime != null && endTime != null) {
              final start = int.parse(startTime);
              final end = int.parse(endTime);
              totalMinutes += ((end - start) / 1000 / 60).round();
            }
          }
          moveMinutes = totalMinutes;
        }
      } catch (_) {
        // Ignore fallback errors
      }
    }

    return FitnessData(
      steps: steps,
      distance: distance,
      calories: calories,
      heartRate: heartRate,
      moveMin: moveMinutes,
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
      final dataSources = await _restClient.getDataSources(dataTypeName: _dataTypeHeartRate);
      if (dataSources.isNotEmpty) {
        List<double> heartRates = [];
        for (var ds in dataSources) {
          try {
            final dataSourceId = ds['dataStreamId'] ?? ds['dataSourceId'];
            if (dataSourceId == null) continue;
            
            final dataset = await _restClient.getDataset(
              dataSourceId: dataSourceId as String,
              startTime: startDate,
              endTime: endDate,
            );

            final point = dataset['point'] as List<dynamic>?;
            if (point == null || point.isEmpty) continue;

            for (var p in point) {
              final value = p['value'] as List<dynamic>?;
              if (value == null || value.isEmpty) continue;

              for (var v in value) {
                double? hr;
                if (v['fpVal'] != null) {
                  hr = (v['fpVal'] as num).toDouble();
                } else if (v['intVal'] != null) {
                  hr = (v['intVal'] as num).toDouble();
                }
                if (hr != null) {
                  heartRates.add(hr);
                }
              }
            }
          } catch (e) {
            continue;
          }
        }

        if (heartRates.isNotEmpty) {
          averageHeartRate = heartRates.reduce((a, b) => a + b) / heartRates.length;
        }
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

      final dataSourceId = await _restClient.createOrGetDataSource(
        dataTypeName: _dataTypeSteps,
        dataStreamName: 'befit_steps',
        deviceManufacturer: 'BeFit',
        deviceModel: 'BeFit App',
        deviceType: 'phone',
      );

      await _restClient.writeDataPoint(
        dataSourceId: dataSourceId,
        dataTypeName: _dataTypeSteps,
        value: steps,
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

      final dataSourceId = await _restClient.createOrGetDataSource(
        dataTypeName: _dataTypeHeartRate,
        dataStreamName: 'befit_heart_rate',
        deviceManufacturer: 'BeFit',
        deviceModel: 'BeFit App',
        deviceType: 'phone',
      );

      await _restClient.writeFloatDataPoint(
        dataSourceId: dataSourceId,
        dataTypeName: _dataTypeHeartRate,
        value: heartRate,
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

      final dataSourceId = await _restClient.createOrGetDataSource(
        dataTypeName: _dataTypeWeight,
        dataStreamName: 'befit_weight',
        deviceManufacturer: 'BeFit',
        deviceModel: 'BeFit App',
        deviceType: 'scale',
      );

      await _restClient.writeFloatDataPoint(
        dataSourceId: dataSourceId,
        dataTypeName: _dataTypeWeight,
        value: weight,
        startTime: date,
        endTime: endTime,
      );
    } catch (e) {
      throw Exception('Failed to write weight: $e');
    }
  }
}

