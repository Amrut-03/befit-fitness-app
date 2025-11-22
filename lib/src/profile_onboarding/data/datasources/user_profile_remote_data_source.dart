import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Remote data source for user profile operations in Firestore
abstract class UserProfileRemoteDataSource {
  /// Save or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required String documentId,
    required UserProfile profile,
  });

  /// Get user profile by document ID (email)
  Future<UserProfile?> getUserProfile(String documentId);

  /// Check if user profile is complete
  Future<bool> isProfileComplete(String documentId);

  /// Update auth user info (email/photo) on profile document
  Future<void> updateAuthUserInfo({
    required String documentId,
    required String? userId,
    required String? email,
    required String? photoUrl,
  });
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  UserProfileRemoteDataSourceImpl({required this.firestore});

  /// Calculate age from date of birth
  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  Future<void> saveUserProfile({
    required String userId,
    required String documentId,
    required UserProfile profile,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      
      // Split name into firstName and lastName
      final nameParts = (profile.name ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : null;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

      // Calculate age from date of birth
      final age = _calculateAge(profile.dateOfBirth);

      final profileData = {
        'id': userId,
        'email': documentId,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
        'age': age,
        'gender': profile.gender,
        'workoutType': profile.workoutType,
        'purpose': profile.purpose,
        'height': null, // Can be added later
        'weight': null, // Can be added later
        'phoneNumber': null, // Can be added later
        'photoUrl': null, // Will be set from auth user if available
        'updatedAt': now,
      };

      // Check if document exists to determine if we should set createdAt
      final docRef = firestore.collection('userdata').doc(documentId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        profileData['createdAt'] = now;
      }

      await docRef.set(profileData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String documentId) async {
    try {
      final docSnapshot = await firestore.collection('userdata').doc(documentId).get();
      
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      final data = docSnapshot.data()!;
      
      // Combine firstName and lastName into name
      final firstName = data['firstName'] as String?;
      final lastName = data['lastName'] as String?;
      final name = [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');

      // Parse dateOfBirth
      DateTime? dateOfBirth;
      if (data['dateOfBirth'] != null) {
        if (data['dateOfBirth'] is Timestamp) {
          dateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
        } else if (data['dateOfBirth'] is String) {
          dateOfBirth = DateTime.parse(data['dateOfBirth'] as String);
        }
      }

      return UserProfile(
        name: name.isNotEmpty ? name : null,
        dateOfBirth: dateOfBirth,
        gender: data['gender'] as String?,
        workoutType: data['workoutType'] as String?,
        purpose: data['purpose'] as String?,
        photoUrl: data['photoUrl'] as String?,
        isProfileComplete: _isProfileComplete(data),
      );
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<bool> isProfileComplete(String documentId) async {
    try {
      final profile = await getUserProfile(documentId);
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      return false;
    }
  }

  bool _isProfileComplete(Map<String, dynamic> data) {
    // Profile is complete if all required fields are present
    return data['firstName'] != null &&
        data['dateOfBirth'] != null &&
        data['gender'] != null &&
        data['workoutType'] != null &&
        data['purpose'] != null;
  }

  @override
  Future<void> updateAuthUserInfo({
    required String documentId,
    required String? userId,
    required String? email,
    required String? photoUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email != null) {
        updateData['email'] = email;
      }

      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      if (userId != null) {
        updateData['id'] = userId;
      }

      await firestore.collection('userdata').doc(documentId).set(
            updateData,
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update auth user info: ${e.toString()}');
    }
  }
}

