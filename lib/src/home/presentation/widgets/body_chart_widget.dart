import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';

/// Body chart widget that uses Home BLoC for state management
class BodyChartWidget extends StatelessWidget {
  const BodyChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (state is HomeError) {
          return Center(
            child: Text(
              state.message,
              style: GoogleFonts.ubuntu(color: Colors.white),
            ),
          );
        }

        if (state is HomeLoaded) {
          // Initialize body chart if not already initialized
          if (state.selectedMuscles.isEmpty && state.disabledMuscles.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<HomeBloc>().add(const InitializeBodyChartEvent());
            });
          }
          return _BodyChartContent(state: state);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _BodyChartContent extends StatelessWidget {
  final HomeLoaded state;

  const _BodyChartContent({required this.state});

  String _muscleToBodyPart(Muscle muscle) {
    switch (muscle) {
      case Muscle.chestLeft:
      case Muscle.chestRight:
        return 'chest';
      case Muscle.deltsLeft:
      case Muscle.deltsRight:
        return 'shoulders';
      case Muscle.bicepsLeft:
      case Muscle.bicepsRight:
      case Muscle.tricepsLeft:
      case Muscle.tricepsRight:
      case Muscle.forearmsLeft:
      case Muscle.forearmsRight:
        return 'upper arms';
      case Muscle.abs:
        return 'waist';
      case Muscle.quadsLeft:
      case Muscle.quadsRight:
      case Muscle.hamstringsLeft:
      case Muscle.hamstringsRight:
      case Muscle.calvesLeft:
      case Muscle.calvesRight:
      case Muscle.glutesLeft:
      case Muscle.glutesRight:
        return 'upper legs';
      case Muscle.latsBackLeft:
      case Muscle.latsBackRight:
      case Muscle.lowerLatsBackLeft:
      case Muscle.lowerLatsBackRight:
        return 'back';
      case Muscle.trapsLeft:
      case Muscle.trapsRight:
        return 'shoulders';
      default:
        return '';
    }
  }

  String? _getPrimaryBodyPart(Set<Muscle> selectedMuscles) {
    if (selectedMuscles.isEmpty) return null;

    final Map<String, int> bodyPartCounts = {};
    for (final muscle in selectedMuscles) {
      final bodyPart = _muscleToBodyPart(muscle);
      if (bodyPart.isNotEmpty) {
        bodyPartCounts[bodyPart] = (bodyPartCounts[bodyPart] ?? 0) + 1;
      }
    }

    if (bodyPartCounts.isEmpty) return null;

    String? primaryBodyPart;
    int maxCount = 0;
    bodyPartCounts.forEach((bodyPart, count) {
      if (count > maxCount) {
        maxCount = count;
        primaryBodyPart = bodyPart;
      }
    });
    return primaryBodyPart;
  }

  void _navigateToWorkoutScreen(BuildContext context) {
    if (state.selectedMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one muscle to search for workouts.',
            style: GoogleFonts.ubuntu(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final primaryBodyPart = _getPrimaryBodyPart(state.selectedMuscles);

    if (primaryBodyPart != null && primaryBodyPart.isNotEmpty) {
      context.push('/workout-list?bodyPart=$primaryBodyPart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not determine a primary body part from your selection.',
            style: GoogleFonts.ubuntu(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Chart',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          // Selection header
          if (state.selectedMuscles.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${state.selectedMuscles.length} muscle${state.selectedMuscles.length == 1 ? '' : 's'}',
                    style: GoogleFonts.ubuntu(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<HomeBloc>().add(const ClearAllMusclesEvent());
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Search Workout Button
          if (state.selectedMuscles.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              child: ElevatedButton(
                onPressed: () => _navigateToWorkoutScreen(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Search Workouts',
                      style: GoogleFonts.ubuntu(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 450.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Body view with flip option
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Header with view label and flip button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.isFrontView ? 'Front' : 'Back',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.flip,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              context.read<HomeBloc>().add(const ToggleViewEvent());
                            },
                            tooltip: 'Flip view',
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      // Body SVG
                      Expanded(
                        child: InteractiveBodySvg(
                          isFront: state.isFrontView,
                          selectedMuscles: state.selectedMuscles,
                          disabledMuscles: state.disabledMuscles,
                          onMuscleTap: (muscle) {
                            context.read<HomeBloc>().add(ToggleMuscleEvent(muscle));
                          },
                          onMuscleLongPress: (muscle) {
                            context.read<HomeBloc>().add(ToggleMuscleDisabledEvent(muscle));
                          },
                          highlightColor: AppColors.primary,
                          disabledColor: Colors.grey.withOpacity(0.5),
                          selectedStrokeWidth: 2.5,
                          unselectedStrokeWidth: 1.0,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          hitTestPadding: 5.0,
                          tooltipBuilder: (muscle) => muscle.displayName,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Vertical scrollable muscle selector
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Text(
                            'Muscles',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildMusclePicker(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusclePicker(BuildContext context) {
    final allMuscles = Muscle.values;
    
    final frontMuscles = allMuscles.where((m) => 
      m == Muscle.chestLeft || m == Muscle.chestRight ||
      m == Muscle.deltsLeft || m == Muscle.deltsRight ||
      m == Muscle.bicepsLeft || m == Muscle.bicepsRight ||
      m == Muscle.tricepsLeft || m == Muscle.tricepsRight ||
      m == Muscle.forearmsLeft || m == Muscle.forearmsRight ||
      m == Muscle.abs ||
      m == Muscle.quadsLeft || m == Muscle.quadsRight ||
      m == Muscle.calvesLeft || m == Muscle.calvesRight ||
      m == Muscle.trapsLeft || m == Muscle.trapsRight
    ).toList();
    
    final backMuscles = allMuscles.where((m) =>
      m == Muscle.latsBackLeft || m == Muscle.latsBackRight ||
      m == Muscle.lowerLatsBackLeft || m == Muscle.lowerLatsBackRight ||
      m == Muscle.glutesLeft || m == Muscle.glutesRight ||
      m == Muscle.hamstringsLeft || m == Muscle.hamstringsRight
    ).toList();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      children: [
        if (state.isFrontView) ...[
          _buildMuscleSection(context, 'Front Muscles', frontMuscles),
        ] else ...[
          _buildMuscleSection(context, 'Back Muscles', backMuscles),
        ],
      ],
    );
  }

  Widget _buildMuscleSection(BuildContext context, String title, List<Muscle> muscles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            title,
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...muscles.map((muscle) {
          final isSelected = state.selectedMuscles.contains(muscle);
          final isDisabled = state.disabledMuscles.contains(muscle);
          
          return Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: GestureDetector(
              onTap: () {
                context.read<HomeBloc>().add(ToggleMuscleEvent(muscle));
              },
              onLongPress: () {
                context.read<HomeBloc>().add(ToggleMuscleDisabledEvent(muscle));
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.2)
                      : isSelected
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : isSelected
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        muscle.displayName,
                        style: GoogleFonts.ubuntu(
                          color: isDisabled
                              ? Colors.grey
                              : isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                          fontSize: 11.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                    if (isDisabled)
                      Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 14.sp,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
