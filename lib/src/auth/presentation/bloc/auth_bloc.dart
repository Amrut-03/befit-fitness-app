import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:befit_fitness_app/core/utils/logger.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/handle_authenticated_user_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/sign_out_usecase.dart';
import 'package:befit_fitness_app/src/auth/domain/usecase/get_current_user_usecase.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';

/// BLoC for managing authentication state and operations
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSignInUseCase googleSignInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final HandleAuthenticatedUserUseCase handleAuthenticatedUserUseCase;

  AuthBloc({
    required this.googleSignInUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.handleAuthenticatedUserUseCase,
  }) : super(const AuthInitial()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
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
        // Log error for monitoring
        AppLogger.e(
          'AuthBloc: Sign-in failed',
          failure,
          StackTrace.current,
        );

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
        // Log error for monitoring
        AppLogger.e(
          'AuthBloc: Failed to handle authenticated user',
          failure,
          StackTrace.current,
        );
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

    final result = await signOutUseCase();

    result.fold(
      (failure) {
        // Log error for monitoring
        AppLogger.e(
          'AuthBloc: Sign-out failed',
          failure,
          StackTrace.current,
        );
        emit(AuthError(failure.message));
      },
      (_) => emit(const Unauthenticated()),
    );
  }


  /// Check current authentication state
  Future<void> _onCheckAuthState(
    CheckAuthStateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) {
        // Log error for monitoring
        AppLogger.e(
          'AuthBloc: Failed to check auth state',
          failure,
          StackTrace.current,
        );
        emit(AuthError(failure.message));
      },
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  @override
  Future<void> close() {
    AppLogger.d('AuthBloc: Closing');
    return super.close();
  }
}
