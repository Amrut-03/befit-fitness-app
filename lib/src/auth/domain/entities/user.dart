import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, emailVerified];
}
