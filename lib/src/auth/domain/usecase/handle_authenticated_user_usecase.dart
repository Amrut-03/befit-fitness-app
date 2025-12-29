import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/auth/core/errors/failures.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Result class for authenticated user handling
class AuthenticatedUserResult {
  final bool isProfileComplete;
  final UserProfile? mergedProfile;

  const AuthenticatedUserResult({
    required this.isProfileComplete,
    this.mergedProfile,
  });
}

/// Use case for handling authenticated user navigation logic
class HandleAuthenticatedUserUseCase {
  final UserProfileRepository profileRepository;

  HandleAuthenticatedUserUseCase(this.profileRepository);

  /// Handle authenticated user - update profile info and check completion
  Future<Either<Failure, AuthenticatedUserResult>> call() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser == null) {
        return Left(AuthFailure('No authenticated user found'));
      }

      // Update auth user info (email and photoUrl) in Firestore
      final documentId = (firebaseUser.email ?? firebaseUser.uid).toLowerCase();

      try {
        await profileRepository.updateAuthUserInfo(
          documentId: documentId,
          userId: firebaseUser.uid,
          email: firebaseUser.email,
          photoUrl: firebaseUser.photoURL,
        );
      } catch (e) {
        // Continue even if update fails
        // Log error but don't fail the operation
      }

      // Check if profile is complete
      bool isComplete = false;
      try {
        isComplete = await profileRepository.isProfileComplete(documentId);
      } catch (e) {
        // If check fails, assume profile is not complete
        isComplete = false;
      }

      if (isComplete) {
        return Right(AuthenticatedUserResult(isProfileComplete: true));
      }

      // Profile not complete - get existing profile and merge with auth data
      UserProfile? existingProfile;
      try {
        existingProfile = await profileRepository.getUserProfile(documentId);
      } catch (e) {
        // If get fails, use empty profile
        existingProfile = null;
      }

      // Get auth account data for auto-filling
      final authName = firebaseUser.displayName;
      final authPhotoUrl = firebaseUser.photoURL;

      // Merge: Use auth data for name/photo (always auto-fill)
      // Keep existing profile data for other fields (DOB, gender, workout, purpose)
      final mergedProfile = (existingProfile ?? const UserProfile()).copyWith(
        // Always use auth name if available (auto-fill)
        name: (authName != null && authName.isNotEmpty) 
            ? authName 
            : existingProfile?.name,
        // Always use auth photo if available (auto-fill)
        photoUrl: (authPhotoUrl != null && authPhotoUrl.isNotEmpty)
            ? authPhotoUrl
            : existingProfile?.photoUrl,
      );

      return Right(AuthenticatedUserResult(
        isProfileComplete: false,
        mergedProfile: mergedProfile,
      ));
    } catch (e) {
      return Left(AuthFailure('Error handling authenticated user: ${e.toString()}'));
    }
  }
}

