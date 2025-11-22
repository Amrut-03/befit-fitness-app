import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:befit_fitness_app/src/home/core/errors/failures.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_health_metrics_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_user_profile_usecase.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';

/// BLoC for managing home screen state and operations
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHealthMetricsUseCase getHealthMetricsUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;

  HomeBloc({
    required this.getHealthMetricsUseCase,
    required this.getUserProfileUseCase,
  }) : super(const HomeInitial()) {
    on<FetchHomeDataEvent>(_onFetchHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }

  Future<void> _onFetchHomeData(
    FetchHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    // Fetch both health metrics and user profile in parallel
    final healthMetricsResult =
        await getHealthMetricsUseCase(event.email);
    final userProfileResult = await getUserProfileUseCase(event.email);

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
        await getHealthMetricsUseCase(event.email);
    final userProfileResult = await getUserProfileUseCase(event.email);

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

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}

