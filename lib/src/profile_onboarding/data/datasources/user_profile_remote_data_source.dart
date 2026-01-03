import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Remote data source for user profile operations in Firestore
abstract class UserProfileRemoteDataSource {
  /// Save or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required UserProfile profile,
  });

  /// Save partial user profile (for intermediate saves during onboarding)
  Future<void> savePartialUserProfile({
    required String userId,
    required UserProfile profile,
  });

  /// Get user profile by user ID (uid)
  Future<UserProfile?> getUserProfile(String userId);

  /// Check if user profile is complete
  Future<bool> isProfileComplete(String userId);

  /// Update auth user info (email/photo) on profile document
  Future<void> updateAuthUserInfo({
    required String userId,
    required String? email,
    required String? photoUrl,
    required String? authProvider,
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
    required UserProfile profile,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      
      // Split name into firstName and lastName
      final nameParts = (profile.name ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : null;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

      // Prepare nested structure using dot notation for proper nested map merging
      final docRef = firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();
      
      final updateData = <String, dynamic>{};
      
      // Update profile map using dot notation to merge nested fields
      if (firstName != null) updateData['profile.firstName'] = firstName;
      if (lastName != null) updateData['profile.lastName'] = lastName;
      if (profile.gender != null) updateData['profile.gender'] = profile.gender;
      if (profile.photoUrl != null) updateData['profile.photoUrl'] = profile.photoUrl;
      if (profile.workoutType != null) updateData['profile.workoutType'] = profile.workoutType;
      if (profile.purpose != null) updateData['profile.purpose'] = profile.purpose;
      // Save isProfileComplete flag
      updateData['profile.isProfileComplete'] = profile.isProfileComplete;
      
      // Update health map (dateOfBirth is stored here)
      if (profile.dateOfBirth != null) {
        updateData['health.dateOfBirth'] = Timestamp.fromDate(profile.dateOfBirth!);
      }
      updateData['health.updatedAt'] = now;
      
      // Set createdAt in meta if document doesn't exist
      if (!docSnapshot.exists) {
        updateData['meta.createdAt'] = now;
      }

      await docRef.set(updateData, SetOptions(merge: true));
      
      // Verify the data was written by reading it back
      // This ensures Firestore has written the data before we continue
      await Future.delayed(const Duration(milliseconds: 200));
      final verifyDoc = await docRef.get();
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data();
        final verifyProfile = verifyData?['profile'] as Map<String, dynamic>? ?? {};
        final savedIsComplete = verifyProfile['isProfileComplete'] as bool? ?? false;
        if (savedIsComplete != profile.isProfileComplete) {
          // If not saved correctly, try one more time
          await docRef.set(updateData, SetOptions(merge: true));
        }
      }
    } catch (e) {
      throw Exception('Failed to save user profile: ${e.toString()}');
    }
  }

  @override
  Future<void> savePartialUserProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      
      // Split name into firstName and lastName
      final nameParts = (profile.name ?? '').split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : null;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

      // Prepare nested structure using dot notation for proper nested map merging
      final docRef = firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();
      
      final updateData = <String, dynamic>{};
      
      // Update profile map using dot notation to merge nested fields
      if (firstName != null) updateData['profile.firstName'] = firstName;
      if (lastName != null) updateData['profile.lastName'] = lastName;
      if (profile.gender != null) updateData['profile.gender'] = profile.gender;
      if (profile.photoUrl != null) updateData['profile.photoUrl'] = profile.photoUrl;
      if (profile.workoutType != null) updateData['profile.workoutType'] = profile.workoutType;
      if (profile.purpose != null) updateData['profile.purpose'] = profile.purpose;
      // Save isProfileComplete as false for partial saves
      updateData['profile.isProfileComplete'] = false;
      
      // Update health map (dateOfBirth is stored here)
      if (profile.dateOfBirth != null) {
        updateData['health.dateOfBirth'] = Timestamp.fromDate(profile.dateOfBirth!);
      }
      updateData['health.updatedAt'] = now;
      
      // Set createdAt in meta if document doesn't exist
      if (!docSnapshot.exists) {
        updateData['meta.createdAt'] = now;
      }

      await docRef.set(updateData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save partial user profile: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await firestore.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      final data = docSnapshot.data()!;
      
      // Firestore stores dot-notation fields as flat keys (e.g., "profile.firstName")
      // So we need to read from flat keys and reconstruct the nested structure
      
      // Read profile fields from flat keys
      final firstName = data['profile.firstName'] as String?;
      final lastName = data['profile.lastName'] as String?;
      final gender = data['profile.gender'] as String?;
      final workoutType = data['profile.workoutType'] as String?;
      final purpose = data['profile.purpose'] as String?;
      final photoUrl = data['profile.photoUrl'] as String?;
      final isProfileComplete = data['profile.isProfileComplete'] as bool? ?? false;
      
      // Combine firstName and lastName into name
      final name = [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');

      // Read health fields from flat keys
      DateTime? dateOfBirth;
      final dateOfBirthValue = data['health.dateOfBirth'];
      if (dateOfBirthValue != null) {
        if (dateOfBirthValue is Timestamp) {
          dateOfBirth = dateOfBirthValue.toDate();
        } else if (dateOfBirthValue is String) {
          dateOfBirth = DateTime.parse(dateOfBirthValue);
        }
      }

      return UserProfile(
        name: name.isNotEmpty ? name : null,
        dateOfBirth: dateOfBirth,
        gender: gender,
        workoutType: workoutType,
        purpose: purpose,
        photoUrl: photoUrl,
        isProfileComplete: isProfileComplete,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<bool> isProfileComplete(String userId) async {
    try {
      print('[UserProfileRemoteDataSource] Checking profile completion for userId: $userId');
      final docSnapshot = await firestore.collection('users').doc(userId).get();
      
      print('[UserProfileRemoteDataSource] Document exists: ${docSnapshot.exists}');
      
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        print('[UserProfileRemoteDataSource] Document does not exist or data is null. Returning false.');
        return false;
      }

      final data = docSnapshot.data()!;
      print('[UserProfileRemoteDataSource] Document data keys: ${data.keys.toList()}');
      
      // Firestore stores dot-notation fields as flat keys (e.g., "profile.isProfileComplete")
      // So we need to check the flat key directly, not as a nested map
      final isCompleteKey = 'profile.isProfileComplete';
      
      // First try to get from flat key (dot notation)
      if (data.containsKey(isCompleteKey)) {
        final isComplete = data[isCompleteKey] as bool? ?? false;
        print('[UserProfileRemoteDataSource] Found isProfileComplete in flat key: $isComplete');
        return isComplete;
      }
      
      // Fallback: try nested map structure (in case data was saved differently)
      final profile = data['profile'] as Map<String, dynamic>?;
      if (profile != null && profile.isNotEmpty) {
        final isComplete = profile['isProfileComplete'] as bool? ?? false;
        print('[UserProfileRemoteDataSource] Found isProfileComplete in nested map: $isComplete');
        return isComplete;
      }
      
      // If neither structure found, return false
      print('[UserProfileRemoteDataSource] isProfileComplete not found in either flat key or nested map. Returning false.');
      return false;
    } catch (e) {
      // Throw exception instead of returning false to distinguish read errors
      // This allows the router to retry or handle errors appropriately
      print('[UserProfileRemoteDataSource] ERROR checking profile completion: $e');
      print('[UserProfileRemoteDataSource] Stack trace: ${StackTrace.current}');
      throw Exception('Failed to check profile completion: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAuthUserInfo({
    required String userId,
    required String? email,
    required String? photoUrl,
    required String? authProvider,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final updateData = <String, dynamic>{};
      
      // Update meta map using dot notation for proper nested map merging
      updateData['meta.lastActiveAt'] = now;
      
      if (email != null) {
        updateData['meta.email'] = email;
      }
      
      if (authProvider != null) {
        updateData['meta.authProvider'] = authProvider;
      }
      
      // Set createdAt and isProfileComplete if document doesn't exist
      final docRef = firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        updateData['meta.createdAt'] = now;
        // Set isProfileComplete to false when user first signs in
        updateData['profile.isProfileComplete'] = false;
      }
      
      // Update profile map with photoUrl using dot notation
      if (photoUrl != null) {
        updateData['profile.photoUrl'] = photoUrl;
      }

      await docRef.set(updateData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update auth user info: ${e.toString()}');
    }
  }
}

