import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/profile_onboarding/domain/models/user_profile.dart';

/// Use case for saving user profile
class SaveUserProfileUseCase {
  final UserProfileRepository profileRepository;

  SaveUserProfileUseCase(this.profileRepository);

  /// Save complete user profile
  Future<void> call(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Save complete profile
    final completeProfile = profile.copyWith(isProfileComplete: true);
    final documentId = (user.email ?? user.uid).toLowerCase();

    await profileRepository.saveUserProfile(
      userId: user.uid,
      documentId: documentId,
      profile: completeProfile,
    );

    // Update auth user info (email and photoUrl)
    await profileRepository.updateAuthUserInfo(
      documentId: documentId,
      userId: user.uid,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}

