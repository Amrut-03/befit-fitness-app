import 'package:befit_fitness_app/src/profile_onboarding/data/datasources/user_profile_remote_data_source.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  Future<void> saveUserProfile({
    required String userId,
    required UserProfile profile,
  });
  Future<void> savePartialUserProfile({
    required String userId,
    required UserProfile profile,
  });
  Future<UserProfile?> getUserProfile(String userId);
  Future<bool> isProfileComplete(String userId);
  Future<void> updateAuthUserInfo({
    required String userId,
    required String? email,
    required String? photoUrl,
    required String? authProvider,
  });
}

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;

  UserProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> saveUserProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    await remoteDataSource.saveUserProfile(
      userId: userId,
      profile: profile,
    );
  }

  @override
  Future<void> savePartialUserProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    await remoteDataSource.savePartialUserProfile(
      userId: userId,
      profile: profile,
    );
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    return await remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<bool> isProfileComplete(String userId) async {
    return await remoteDataSource.isProfileComplete(userId);
  }

  @override
  Future<void> updateAuthUserInfo({
    required String userId,
    required String? email,
    required String? photoUrl,
    required String? authProvider,
  }) async {
    await remoteDataSource.updateAuthUserInfo(
      userId: userId,
      email: email,
      photoUrl: photoUrl,
      authProvider: authProvider,
    );
  }
}

