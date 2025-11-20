/// User profile model for onboarding
class UserProfile {
  final String? name;
  final DateTime? dateOfBirth;
  final String? gender; // 'male', 'female', 'other'
  final String? workoutType; // e.g., 'cardio', 'strength', 'yoga', etc.
  final String? purpose; // e.g., 'weight_loss', 'muscle_gain', 'general_fitness', etc.
  final String? photoUrl;
  final bool isProfileComplete;

  const UserProfile({
    this.name,
    this.dateOfBirth,
    this.gender,
    this.workoutType,
    this.purpose,
    this.photoUrl,
    this.isProfileComplete = false,
  });

  UserProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? workoutType,
    String? purpose,
    String? photoUrl,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      workoutType: workoutType ?? this.workoutType,
      purpose: purpose ?? this.purpose,
      photoUrl: photoUrl ?? this.photoUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  bool get isFirstTimeUser => !isProfileComplete;
}

