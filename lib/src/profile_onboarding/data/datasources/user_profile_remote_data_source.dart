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
      
      // Update health map (dateOfBirth, height, weight are stored here)
      if (profile.dateOfBirth != null) {
        updateData['health.dateOfBirth'] = Timestamp.fromDate(profile.dateOfBirth!);
      }
      if (profile.height != null) {
        updateData['health.height'] = profile.height; // in cm
      }
      if (profile.weight != null) {
        updateData['health.weight'] = profile.weight; // in kg
      }
      updateData['health.updatedAt'] = now;
      // Remove duplicate fields so only health.height and health.weight are used
      updateData['health.heightCm'] = FieldValue.delete();
      updateData['health.weightKg'] = FieldValue.delete();

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
      
      // Update health map (dateOfBirth, height, weight are stored here)
      if (profile.dateOfBirth != null) {
        updateData['health.dateOfBirth'] = Timestamp.fromDate(profile.dateOfBirth!);
      }
      if (profile.height != null) {
        updateData['health.height'] = profile.height; // in cm
      }
      if (profile.weight != null) {
        updateData['health.weight'] = profile.weight; // in kg
      }
      updateData['health.updatedAt'] = now;
      // Remove duplicate fields so only health.height and health.weight are used
      updateData['health.heightCm'] = FieldValue.delete();
      updateData['health.weightKg'] = FieldValue.delete();

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
      
      // Firestore stores dot-notation fields as nested maps
      // Try both nested structure and flat keys for compatibility
      
      // Read profile fields - try nested first, then flat keys
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      final firstName = profile['firstName'] as String? ?? data['profile.firstName'] as String?;
      final lastName = profile['lastName'] as String? ?? data['profile.lastName'] as String?;
      final gender = profile['gender'] as String? ?? data['profile.gender'] as String?;
      final workoutType = profile['workoutType'] as String? ?? data['profile.workoutType'] as String?;
      final purpose = profile['purpose'] as String? ?? data['profile.purpose'] as String?;
      final photoUrl = profile['photoUrl'] as String? ?? data['profile.photoUrl'] as String?;
      final isProfileComplete = profile['isProfileComplete'] as bool? ?? data['profile.isProfileComplete'] as bool? ?? false;
      
      // Combine firstName and lastName into name
      final name = [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');

      // Read health fields - try nested first, then flat keys
      final health = data['health'] as Map<String, dynamic>? ?? {};
      DateTime? dateOfBirth;
      final dateOfBirthValue = health['dateOfBirth'] ?? data['health.dateOfBirth'];
      if (dateOfBirthValue != null) {
        if (dateOfBirthValue is Timestamp) {
          dateOfBirth = dateOfBirthValue.toDate();
        } else if (dateOfBirthValue is String) {
          dateOfBirth = DateTime.parse(dateOfBirthValue);
        }
      }

      // Read height and weight from health map - use only health.height and health.weight
      // (no health.heightCm / health.weightKg; those are removed on save)
      double? height;
      final heightValue = health['height'] ?? data['health.height'];
      if (heightValue != null) {
        height = (heightValue as num).toDouble();
      }

      double? weight;
      final weightValue = health['weight'] ?? data['health.weight'];
      if (weightValue != null) {
        weight = (weightValue as num).toDouble();
      }

      return UserProfile(
        name: name.isNotEmpty ? name : null,
        dateOfBirth: dateOfBirth,
        gender: gender,
        workoutType: workoutType,
        purpose: purpose,
        photoUrl: photoUrl,
        height: height,
        weight: weight,
        isProfileComplete: isProfileComplete,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<bool> isProfileComplete(String userId) async {
    try {
      final docSnapshot = await firestore.collection('users').doc(userId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) return false;

      final data = docSnapshot.data()!;
      const isCompleteKey = 'profile.isProfileComplete';
      if (data.containsKey(isCompleteKey)) {
        return data[isCompleteKey] as bool? ?? false;
      }
      final profile = data['profile'] as Map<String, dynamic>?;
      if (profile != null && profile.isNotEmpty) {
        return profile['isProfileComplete'] as bool? ?? false;
      }
      return false;
    } catch (e) {
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

