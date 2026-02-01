import 'package:dartz/dartz.dart';
import 'package:befit_fitness_app/core/error/failures.dart';
import 'package:befit_fitness_app/core/usecase/usecase.dart';
import 'package:befit_fitness_app/src/workout/domain/repositories/exercise_repository.dart';

/// Result of exercise filter options (body parts, targets, equipment)
class ExerciseFiltersResult {
  final List<String> bodyParts;
  final List<String> targets;
  final List<String> equipment;

  const ExerciseFiltersResult({
    required this.bodyParts,
    required this.targets,
    required this.equipment,
  });
}

/// Use case for fetching exercise filter options (SRP: one use case)
class GetExerciseFiltersUseCase extends UseCaseNoParams<ExerciseFiltersResult> {
  final ExerciseRepository repository;

  GetExerciseFiltersUseCase(this.repository);

  @override
  Future<Either<Failure, ExerciseFiltersResult>> call() async {
    final bodyPartsResult = await repository.getBodyPartList();
    final targetsResult = await repository.getTargetList();
    final equipmentResult = await repository.getEquipmentList();

    return bodyPartsResult.fold(
      (l) => Left(l),
      (bodyParts) => targetsResult.fold(
        (l) => Left(l),
        (targets) => equipmentResult.fold(
          (l) => Left(l),
          (equipment) => Right(ExerciseFiltersResult(
            bodyParts: bodyParts,
            targets: targets,
            equipment: equipment,
          )),
        ),
      ),
    );
  }
}
