import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/src/home/domain/entities/health_metrics.dart';
import 'package:befit_fitness_app/src/home/domain/entities/user_profile.dart';

/// Remote data source interface for home data
abstract class HomeRemoteDataSource {
  Future<HealthMetrics> getHealthMetrics(String userId);
  Future<UserProfile> getUserProfile(String userId);
}

/// Implementation of home remote data source
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirebaseFirestore firestore;

  HomeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<HealthMetrics> getHealthMetrics(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return const HealthMetrics();
      }

      final data = userDoc.data();
      final metrics = data?['metrics'] as Map<String, dynamic>? ?? {};
      
      return HealthMetrics(
        bmi: metrics['bmi']?.toDouble(),
        bmr: metrics['bmr']?.toInt(),
        hrc: null, // HRC not in new structure, can be added later if needed
        overallHealthPercentage: null, // Can be calculated from other metrics if needed
      );
    } catch (e) {
      throw Exception('Failed to fetch health metrics: $e');
    }
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        // Get email from meta if available, otherwise use userId
        return UserProfile(email: userId);
      }

      final data = userDoc.data();
      final profile = data?['profile'] as Map<String, dynamic>? ?? {};
      final meta = data?['meta'] as Map<String, dynamic>? ?? {};
      
      // Get email from meta, fallback to userId
      final email = meta['email'] as String? ?? userId;
      
      return UserProfile(
        firstName: profile['firstName'] as String?,
        email: email,
      );
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }
}
