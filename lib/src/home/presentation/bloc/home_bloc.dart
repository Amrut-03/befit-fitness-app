import 'package:befit_fitness_app/src/fitness_tracker/domain/entities/fitness_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart';
import 'package:befit_fitness_app/core/utils/logger.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_health_metrics_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_user_profile_usecase.dart';
import 'package:befit_fitness_app/src/home/domain/usecase/get_fitness_data_with_permissions_usecase.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/fitness_tracker/presentation/services/permission_service.dart';

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
    on<FetchWeeklyFitnessDataEvent>(_onFetchWeeklyFitnessData);
    on<FetchWeightChartDataEvent>(_onFetchWeightChartData);
    on<RegisterWithGoogleFitEvent>(_onRegisterWithGoogleFit);
    // Body Chart events
    on<InitializeBodyChartEvent>(_onInitializeBodyChart);
    on<ToggleMuscleEvent>(_onToggleMuscle);
    on<SelectMultipleMusclesEvent>(_onSelectMultipleMuscles);
    on<ClearAllMusclesEvent>(_onClearAllMuscles);
    on<ToggleViewEvent>(_onToggleView);
    on<ToggleMuscleDisabledEvent>(_onToggleMuscleDisabled);
  }

  Future<void> _onFetchHomeData(
    FetchHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Input validation
    if (event.userId.isEmpty) {
      emit(const HomeError('User ID cannot be empty'));
      return;
    }

    emit(const HomeLoading());

    final today = DateTime.now();
    
    // Fetch health metrics, user profile, and today's fitness data in parallel for faster loading
    // Start all futures first (they begin executing immediately in parallel)
    final healthMetricsFuture = getHealthMetricsUseCase(event.userId);
    final userProfileFuture = getUserProfileUseCase(event.userId);
    final fitnessDataFuture = getFitnessDataWithPermissionsUseCase(today);

    // Await all futures (they run concurrently since started before awaiting)
    final healthMetricsResult = await healthMetricsFuture;
    final userProfileResult = await userProfileFuture;
    final fitnessDataResult = await fitnessDataFuture;

    healthMetricsResult.fold(
      (failure) {
        // Log error for monitoring
        AppLogger.e(
          'HomeBloc: Failed to fetch health metrics',
          failure,
          StackTrace.current,
        );
        // Preserve previous state if available
        if (state is HomeLoaded) {
          final previousState = state as HomeLoaded;
          emit(HomeError(_mapFailureToMessage(failure)));
          emit(previousState);
        } else {
          emit(HomeError(_mapFailureToMessage(failure)));
        }
      },
      (healthMetrics) {
        userProfileResult.fold(
          (failure) {
            // Log error for monitoring
            AppLogger.e(
              'HomeBloc: Failed to fetch user profile',
              failure,
              StackTrace.current,
            );
            // Preserve previous state if available
            if (state is HomeLoaded) {
              final previousState = state as HomeLoaded;
              emit(HomeError(_mapFailureToMessage(failure)));
              emit(previousState);
            } else {
              emit(HomeError(_mapFailureToMessage(failure)));
            }
          },
          (userProfile) {
            // Extract fitness data if available, otherwise null
            FitnessData? fitnessData;
            fitnessDataResult.fold(
              (failure) {
                AppLogger.w(
                  'HomeBloc: Failed to fetch fitness data',
                  failure,
                  StackTrace.current,
                );
              },
              (data) => fitnessData = data,
            );
            
            emit(HomeLoaded(
              healthMetrics: healthMetrics,
              userProfile: userProfile,
              fitnessData: fitnessData,
            ));
          },
        );
      },
    );
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Input validation
    if (event.userId.isEmpty) {
      emit(const HomeError('User ID cannot be empty'));
      return;
    }

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
      (failure) {
        // Log error for monitoring
        AppLogger.e(
          'HomeBloc: Failed to refresh health metrics',
          failure,
          StackTrace.current,
        );
        if (state is HomeLoaded) {
          emit(HomeError(_mapFailureToMessage(failure)));
          emit(state);
        } else {
          emit(HomeError(_mapFailureToMessage(failure)));
        }
      },
      (healthMetrics) {
        userProfileResult.fold(
          (failure) {
            // Log error for monitoring
            AppLogger.e(
              'HomeBloc: Failed to refresh user profile',
              failure,
              StackTrace.current,
            );
            if (state is HomeLoaded) {
              emit(HomeError(_mapFailureToMessage(failure)));
              emit(state);
            } else {
              emit(HomeError(_mapFailureToMessage(failure)));
            }
          },
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
        // Log error for monitoring
        AppLogger.e(
          'HomeBloc: Failed to fetch fitness data',
          failure,
          StackTrace.current,
        );
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

  Future<void> _onFetchWeeklyFitnessData(
    FetchWeeklyFitnessDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;

    final currentState = state as HomeLoaded;
    emit(currentState.copyWith(isFetchingWeeklyData: true));

    final now = DateTime.now();
    final monday = _getMondayOfWeek(now);
    final dates = List.generate(7, (i) => monday.add(Duration(days: i)));

    final results = await Future.wait(
      dates.map((date) => getFitnessDataWithPermissionsUseCase(date)),
    );

    final weeklyData = <FitnessData>[];
    for (int i = 0; i < results.length; i++) {
      results[i].fold(
        (failure) {
          AppLogger.w(
            'HomeBloc: Failed to fetch fitness data for ${dates[i]}',
            failure,
            StackTrace.current,
          );
          weeklyData.add(FitnessData(date: dates[i]));
        },
        (fitnessData) => weeklyData.add(fitnessData),
      );
    }

    emit(currentState.copyWith(
      weeklyFitnessData: weeklyData,
      isFetchingWeeklyData: false,
    ));
  }

  Future<void> _onFetchWeightChartData(
    FetchWeightChartDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;

    final currentState = state as HomeLoaded;
    final now = DateTime.now();
    final dates = List.generate(15, (i) => now.subtract(Duration(days: 14 - i)));

    final results = await Future.wait(
      dates.map((date) => getFitnessDataWithPermissionsUseCase(date)),
    );

    final weightChartData = <FitnessData>[];
    for (int i = 0; i < results.length; i++) {
      results[i].fold(
        (failure) {
          AppLogger.w(
            'HomeBloc: Failed to fetch fitness data for weight chart ${dates[i]}',
            failure,
            StackTrace.current,
          );
          weightChartData.add(FitnessData(date: dates[i]));
        },
        (fitnessData) => weightChartData.add(fitnessData),
      );
    }

    final lastSeven = weightChartData.length >= 7
        ? weightChartData.sublist(weightChartData.length - 7)
        : weightChartData;
    emit(currentState.copyWith(
      weightChartFitnessData: weightChartData,
      weeklyFitnessData: currentState.weeklyFitnessData.isEmpty
          ? lastSeven
          : currentState.weeklyFitnessData,
    ));
  }

  DateTime _getMondayOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
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

  // Body Chart event handlers

  void _onInitializeBodyChart(
    InitializeBodyChartEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(
        selectedMuscles: {},
        disabledMuscles: {},
        isFrontView: true,
      ));
    }
  }

  void _onToggleMuscle(
    ToggleMuscleEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final selectedMuscles = Set<Muscle>.from(currentState.selectedMuscles);
      
      if (selectedMuscles.contains(event.muscle)) {
        selectedMuscles.remove(event.muscle);
      } else {
        selectedMuscles.add(event.muscle);
      }

      emit(currentState.copyWith(selectedMuscles: selectedMuscles));
    }
  }

  void _onSelectMultipleMuscles(
    SelectMultipleMusclesEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final selectedMuscles = Set<Muscle>.from(currentState.selectedMuscles);
      selectedMuscles.addAll(event.muscles);

      emit(currentState.copyWith(selectedMuscles: selectedMuscles));
    }
  }

  void _onClearAllMuscles(
    ClearAllMusclesEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(selectedMuscles: {}));
    }
  }

  void _onToggleView(
    ToggleViewEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(isFrontView: !currentState.isFrontView));
    }
  }

  void _onToggleMuscleDisabled(
    ToggleMuscleDisabledEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final disabledMuscles = Set<Muscle>.from(currentState.disabledMuscles);
      
      if (disabledMuscles.contains(event.muscle)) {
        disabledMuscles.remove(event.muscle);
      } else {
        disabledMuscles.add(event.muscle);
      }

      emit(currentState.copyWith(disabledMuscles: disabledMuscles));
    }
  }

  @override
  Future<void> close() {
    AppLogger.d('HomeBloc: Closing');
    return super.close();
  }
}

