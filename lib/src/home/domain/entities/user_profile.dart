import 'package:equatable/equatable.dart';

/// Entity representing user profile information
class UserProfile extends Equatable {
  final String? firstName;
  final String email;

  const UserProfile({
    this.firstName,
    required this.email,
  });

  @override
  List<Object?> get props => [firstName, email];
}

