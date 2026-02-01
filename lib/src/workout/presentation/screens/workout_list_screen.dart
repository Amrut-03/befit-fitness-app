import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/shimmer_widget.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_bloc.dart';
import 'package:befit_fitness_app/src/workout/presentation/bloc/workout_state.dart';
import 'package:befit_fitness_app/src/workout/presentation/widgets/exercise_card.dart';
import 'package:befit_fitness_app/src/workout/presentation/widgets/exercise_detail_bottom_sheet.dart';

/// Workout list screen (DIP: depends on Bloc only, no direct data source)
class WorkoutListScreen extends StatefulWidget {
  static const String route = '/workout-list';

  final String? initialBodyPart;

  const WorkoutListScreen({
    super.key,
    this.initialBodyPart,
  });

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late WorkoutBloc _bloc;
  bool _hasRequestedInitialExercises = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<WorkoutBloc>();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _bloc.add(const LoadMoreExercisesEvent());
    }
  }

  void _requestInitialExercisesIfNeeded(WorkoutState state) {
    if (_hasRequestedInitialExercises) return;
    if (state is! WorkoutLoaded) return;
    if (state.exercises.isNotEmpty) return;
    if (state.isLoading) return;

    _hasRequestedInitialExercises = true;
    _bloc.add(LoadExercisesEvent(
      reset: true,
      bodyPart: widget.initialBodyPart,
    ));
  }

  void _showExerciseDetails(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailBottomSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          _requestInitialExercisesIfNeeded(state);
        },
        builder: (context, state) {
          if (state is WorkoutLoading) {
            return _buildScaffold(
              body: const ShimmerWorkoutList(itemCount: 10),
            );
          }

          if (state is WorkoutError) {
            return _buildScaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                      SizedBox(height: 16.h),
                      Text(
                        state.message,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () => _bloc.add(const LoadExerciseFiltersEvent()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                      SizedBox(height: 12.h),
                      TextButton(
                        onPressed: () => _bloc.add(const LoadExercisesEvent(reset: true)),
                        child: Text(
                          'Load exercises anyway',
                          style: GoogleFonts.ubuntu(
                            color: AppColors.primary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is WorkoutLoaded) {
            return _buildScaffold(
              state: state,
              body: state.isLoading && state.exercises.isEmpty
                  ? const ShimmerWorkoutList(itemCount: 10)
                  : state.filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: Colors.white.withOpacity(0.5),
                                size: 64.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No exercises found',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            _bloc.add(const ApplyFiltersEvent());
                            _bloc.add(LoadExercisesEvent(
                              reset: true,
                              bodyPart: state.selectedBodyPart,
                              target: state.selectedTarget,
                              equipment: state.selectedEquipment,
                            ));
                            return Future.value();
                          },
                          color: AppColors.primary,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16.w),
                            itemCount: state.filteredExercises.length +
                                (state.hasNextPage ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.filteredExercises.length) {
                                return Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: ShimmerLoading(
                                    child: Container(
                                      height: 80.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final exercise = state.filteredExercises[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: ExerciseCard(
                                  exercise: exercise,
                                  onTap: () =>
                                      _showExerciseDetails(exercise),
                                ),
                              );
                            },
                          ),
                        ),
            );
          }

          if (state is WorkoutFiltersLoading) {
            return _buildScaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          return _buildScaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        },
      );
  }

  Widget _buildScaffold({
    WorkoutLoaded? state,
    required Widget body,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workout Plan',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (state != null) _buildSearchAndFilters(state),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(WorkoutLoaded state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.black,
      child: Column(
        children: [
          TextField(
            style: GoogleFonts.ubuntu(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              hintStyle: GoogleFonts.ubuntu(
                color: Colors.white.withOpacity(0.5),
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            onChanged: (value) => _bloc.add(SearchExercisesEvent(value)),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (state.bodyParts.isNotEmpty)
                  _buildFilterChip(
                    'Body Part',
                    state.selectedBodyPart,
                    state.bodyParts,
                    (value) {
                      _bloc.add(ApplyFiltersEvent(
                        bodyPart: value,
                        target: null,
                        equipment: null,
                      ));
                      _bloc.add(LoadExercisesEvent(
                        reset: true,
                        bodyPart: value,
                      ));
                    },
                  ),
                SizedBox(width: 8.w),
                if (state.targets.isNotEmpty)
                  _buildFilterChip(
                    'Target',
                    state.selectedTarget,
                    state.targets,
                    (value) {
                      _bloc.add(ApplyFiltersEvent(
                        bodyPart: null,
                        target: value,
                        equipment: null,
                      ));
                      _bloc.add(LoadExercisesEvent(reset: true, target: value));
                    },
                  ),
                SizedBox(width: 8.w),
                if (state.equipment.isNotEmpty)
                  _buildFilterChip(
                    'Equipment',
                    state.selectedEquipment,
                    state.equipment,
                    (value) {
                      _bloc.add(ApplyFiltersEvent(
                        bodyPart: null,
                        target: null,
                        equipment: value,
                      ));
                      _bloc.add(LoadExercisesEvent(
                        reset: true,
                        equipment: value,
                      ));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selectedValue != null
              ? AppColors.primary
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selectedValue != null
                ? AppColors.primary
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedValue ?? label,
              style: GoogleFonts.ubuntu(
                color: selectedValue != null ? Colors.black : Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_drop_down,
              color: selectedValue != null ? Colors.black : Colors.white,
              size: 16.sp,
            ),
          ],
        ),
      ),
      onSelected: (value) =>
          onChanged(value == 'Clear' ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Clear', child: Text('Clear filter')),
        ...options.map(
          (option) => PopupMenuItem(value: option, child: Text(option)),
        ),
      ],
    );
  }
}
