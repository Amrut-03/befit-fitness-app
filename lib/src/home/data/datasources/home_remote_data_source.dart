import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';

/// Remote data source interface for home data
abstract class HomeRemoteDataSource {
  Future<HealthMetrics> getHealthMetrics(String email);
  Future<UserProfile> getUserProfile(String email);
}

/// Implementation of home remote data source
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirebaseFirestore firestore;

  HomeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<HealthMetrics> getHealthMetrics(String email) async {
    try {
      final userDoc = await firestore.collection('users').doc(email).get();

      if (!userDoc.exists) {
        return const HealthMetrics();
      }

      final data = userDoc.data();
      return HealthMetrics(
        bmi: data?['BMI']?['value']?.toDouble(),
        bmr: data?['BMR']?['value']?.toInt(),
        hrc: data?['HRC']?['value']?.toInt(),
        overallHealthPercentage: data?['OverallHealthPercentage']?['value']
            ?.toDouble(),
      );
    } catch (e) {
      throw Exception('Failed to fetch health metrics: $e');
    }
  }

  @override
  Future<UserProfile> getUserProfile(String email) async {
    try {
      final userDoc = await firestore.collection('userdata').doc(email).get();

      if (!userDoc.exists) {
        return UserProfile(email: email);
      }

      final data = userDoc.data();
      // Try both 'firstname' and 'firstName' to handle different field names
      return UserProfile(
        firstName: data?['firstName'] ?? data?['firstname'],
        email: email,
      );
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }
}
