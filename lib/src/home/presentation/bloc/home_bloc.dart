import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:befit_fitness_app/src/home/core/errors/failures.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_health_metrics_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_user_profile_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_fitness_data_with_permissions_usecase.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';

/// BLoC for managing home screen state and operations
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHealthMetricsUseCase getHealthMetricsUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final GetFitnessDataWithPermissionsUseCase getFitnessDataWithPermissionsUseCase;
  final PermissionService permissionService;

  HomeBloc({
    required this.getHealthMetricsUseCase,
    required this.getUserProfileUseCase,
    required this.getFitnessDataWithPermissionsUseCase,
    required this.permissionService,
  }) : super(const HomeInitial()) {
    on<FetchHomeDataEvent>(_onFetchHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
    on<FetchFitnessDataEvent>(_onFetchFitnessData);
    on<RegisterWithGoogleFitEvent>(_onRegisterWithGoogleFit);
  }

  Future<void> _onFetchHomeData(
    FetchHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    // Fetch both health metrics and user profile in parallel
    final healthMetricsResult =
        await getHealthMetricsUseCase(event.userId);
    final userProfileResult = await getUserProfileUseCase(event.userId);

    healthMetricsResult.fold(
      (failure) => emit(HomeError(_mapFailureToMessage(failure))),
      (healthMetrics) {
        userProfileResult.fold(
          (failure) => emit(HomeError(_mapFailureToMessage(failure))),
          (userProfile) => emit(HomeLoaded(
            healthMetrics: healthMetrics,
            userProfile: userProfile,
          )),
        );
      },
    );
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Keep current state if loaded, otherwise show loading
    if (state is HomeLoaded) {
      // Don't show loading on refresh, just update data
    } else {
      emit(const HomeLoading());
    }

    // Fetch both health metrics and user profile in parallel
    final healthMetricsResult =
        await getHealthMetricsUseCase(event.userId);
    final userProfileResult = await getUserProfileUseCase(event.userId);

    healthMetricsResult.fold(
      (failure) => emit(HomeError(_mapFailureToMessage(failure))),
      (healthMetrics) {
        userProfileResult.fold(
          (failure) => emit(HomeError(_mapFailureToMessage(failure))),
          (userProfile) {
            // Preserve fitness data if it exists
            final currentState = state;
            final existingFitnessData = currentState is HomeLoaded
                ? currentState.fitnessData
                : null;
            emit(HomeLoaded(
              healthMetrics: healthMetrics,
              userProfile: userProfile,
              fitnessData: existingFitnessData,
            ));
          },
        );
      },
    );
  }

  Future<void> _onFetchFitnessData(
    FetchFitnessDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;

    final currentState = state as HomeLoaded;
    emit(currentState.copyWith(isFetchingFitnessData: true));

    final today = DateTime.now();
    final fitnessDataResult = await getFitnessDataWithPermissionsUseCase(today);

    fitnessDataResult.fold(
      (failure) {
        debugPrint('HomeBloc: Failed to fetch fitness data: ${failure.message}');
        emit(currentState.copyWith(isFetchingFitnessData: false));
      },
      (fitnessData) {
        emit(currentState.copyWith(
          fitnessData: fitnessData,
          isFetchingFitnessData: false,
        ));
      },
    );
  }

  Future<void> _onRegisterWithGoogleFit(
    RegisterWithGoogleFitEvent event,
    Emitter<HomeState> emit,
  ) async {
    await permissionService.tryRegisterWithGoogleFit();
    // After registration, try to fetch fitness data
    add(const FetchFitnessDataEvent());
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}

