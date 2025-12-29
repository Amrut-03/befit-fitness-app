import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/handle_authenticated_user_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/repositories/auth_repository.dart';
import 'package:befit_fitness_app/src/auth/core/errors/failures.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';

/// BLoC for managing authentication state and operations
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSignInUseCase googleSignInUseCase;
  final AuthRepository authRepository;
  final HandleAuthenticatedUserUseCase handleAuthenticatedUserUseCase;

  AuthBloc({
    required this.googleSignInUseCase,
    required this.authRepository,
    required this.handleAuthenticatedUserUseCase,
  }) : super(const AuthInitial()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithEmailPasswordEvent>(_onSignInWithEmailPassword);
    on<SignUpWithEmailPasswordEvent>(_onSignUpWithEmailPassword);
    on<SendEmailVerificationEvent>(_onSendEmailVerification);
    on<ResetPasswordEvent>(_onResetPassword);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStateEvent>(_onCheckAuthState);
    on<HandleAuthenticatedUserEvent>(_onHandleAuthenticatedUser);
  }

  /// Handle Google Sign-In event
  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await googleSignInUseCase();

    result.fold(
      (failure) {
        if (failure is CancellationFailure) {
          // User cancelled - return to unauthenticated state
          emit(const Unauthenticated());
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) {
        emit(Authenticated(user));
        // Automatically handle authenticated user after sign-in
        add(const HandleAuthenticatedUserEvent());
      },
    );
  }

  /// Handle authenticated user event
  Future<void> _onHandleAuthenticatedUser(
    HandleAuthenticatedUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) {
      return; // Can only handle if authenticated
    }

    final currentState = state as Authenticated;
    final result = await handleAuthenticatedUserUseCase();

    result.fold(
      (failure) {
        // On failure, keep authenticated state but log error
        // Don't emit error state as user is still authenticated
      },
      (userResult) {
        // Update authenticated state with profile info
        emit(Authenticated(
          currentState.user,
          isProfileComplete: userResult.isProfileComplete,
          mergedProfile: userResult.mergedProfile,
        ));
      },
    );
  }

  /// Handle sign out event
  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.signOut();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Handle email/password sign-in event
  Future<void> _onSignInWithEmailPassword(
    SignInWithEmailPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.signInWithEmailPassword(
      event.email,
      event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(Authenticated(user));
        // Automatically handle authenticated user after sign-in
        add(const HandleAuthenticatedUserEvent());
      },
    );
  }

  /// Handle email/password sign-up event
  Future<void> _onSignUpWithEmailPassword(
    SignUpWithEmailPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.signUpWithEmailPassword(
      event.email,
      event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        // After sign-up, user is signed out automatically
        // They need to verify their email before signing in
        // Show success message and return to unauthenticated state
        emit(const Unauthenticated());
      },
    );
  }

  /// Handle send email verification event
  Future<void> _onSendEmailVerification(
    SendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.sendEmailVerification();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        // Return to previous state after sending verification
        // Check current user to determine state
        authRepository.getCurrentUser().then((userResult) {
          userResult.fold(
            (failure) => emit(AuthError(failure.message)),
            (user) {
              if (user != null) {
                emit(Authenticated(user));
              } else {
                emit(const Unauthenticated());
              }
            },
          );
        });
      },
    );
  }

  /// Handle reset password event
  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.resetPassword(event.email);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        // Show success message and return to unauthenticated state
        emit(const Unauthenticated());
      },
    );
  }

  /// Check current authentication state
  Future<void> _onCheckAuthState(
    CheckAuthStateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await authRepository.getCurrentUser();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }
}
