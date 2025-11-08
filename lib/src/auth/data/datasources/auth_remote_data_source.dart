import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:befit_fitness_app/src/auth/domain/entities/user.dart' as domain;

/// Remote data source for authentication operations
abstract class AuthRemoteDataSource {
  /// Sign in with Google
  Future<domain.User> signInWithGoogle();

  /// Sign out the current user
  Future<void> signOut();

  /// Get the current authenticated user
  Future<domain.User?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<domain.User> signInWithGoogle() async {
    try {
      // Version 6.1.5: Traditional API - Use signIn() method
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Check if user cancelled the sign-in
      if (googleUser == null) {
        throw Exception('Sign-in was cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Get access token and id token from authentication
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      // On Android, idToken might be null if serverClientId is not configured
      // Make idToken optional for now, but accessToken is required
      if (accessToken == null) {
        throw Exception(
          'Failed to obtain access token from Google. '
          'Please check your Firebase configuration and SHA-1 fingerprint.',
        );
      }

      // idToken is required for Firebase Auth, but might be null on Android
      // without proper serverClientId configuration
      if (idToken == null) {
        throw Exception(
          'Failed to obtain ID token from Google. '
          'Make sure serverClientId (Web Client ID) is configured in GoogleSignIn. '
          'Get it from Firebase Console > Project Settings > Your apps > Web app.',
        );
      }

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Convert Firebase User to domain User
      return domain.User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await googleSignIn.signOut();
      // Sign out from Firebase
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      return domain.User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }
}
