import 'package:befit_fitness_app/src/profile_onboarding/data/datasources/user_profile_remote_data_source.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  Future<void> saveUserProfile({
    required String userId,
    required String documentId,
    required UserProfile profile,
  });
  Future<UserProfile?> getUserProfile(String documentId);
  Future<bool> isProfileComplete(String documentId);
  Future<void> updateAuthUserInfo({
    required String documentId,
    required String? userId,
    required String? email,
    required String? photoUrl,
  });
}

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;

  UserProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> saveUserProfile({
    required String userId,
    required String documentId,
    required UserProfile profile,
  }) async {
    await remoteDataSource.saveUserProfile(
      userId: userId,
      documentId: documentId,
      profile: profile,
    );
  }

  @override
  Future<UserProfile?> getUserProfile(String documentId) async {
    return await remoteDataSource.getUserProfile(documentId);
  }

  @override
  Future<bool> isProfileComplete(String documentId) async {
    return await remoteDataSource.isProfileComplete(documentId);
  }

  @override
  Future<void> updateAuthUserInfo({
    required String documentId,
    required String? userId,
    required String? email,
    required String? photoUrl,
  }) async {
    await remoteDataSource.updateAuthUserInfo(
      documentId: documentId,
      userId: userId,
      email: email,
      photoUrl: photoUrl,
    );
  }
}

