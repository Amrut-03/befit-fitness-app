import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/src/google_fit/core/errors/failures.dart';
import 'package:befit_fitness_app/src/google_fit/domain/entities/fitness_data.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/get_fitness_data_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/request_permissions_usecase.dart';

/// Use case for fetching fitness data with automatic permission handling
class GetFitnessDataWithPermissionsUseCase {
  final GoogleFitRepository repository;
  final GetFitnessDataUseCase getFitnessDataUseCase;
  final RequestPermissionsUseCase requestPermissionsUseCase;

  GetFitnessDataWithPermissionsUseCase({
    required this.repository,
    required this.getFitnessDataUseCase,
    required this.requestPermissionsUseCase,
  });

  Future<Either<FitnessFailure, FitnessData>> call(DateTime date) async {
    final hasPermissionsResult = await repository.hasPermissions();
    
    bool hasPermissions = false;
    hasPermissionsResult.fold(
      (failure) => hasPermissions = false,
      (hasPerms) => hasPermissions = hasPerms,
    );

    if (!hasPermissions) {
      final permissionResult = await requestPermissionsUseCase();
      
      return permissionResult.fold(
        (failure) => Left(failure),
        (granted) async {
          if (!granted) {
            return const Left(PermissionDeniedFailure());
          }
          
          await Future.delayed(const Duration(seconds: 2));
          return await getFitnessDataUseCase(date);
        },
      );
    }

    return await getFitnessDataUseCase(date);
  }
}

