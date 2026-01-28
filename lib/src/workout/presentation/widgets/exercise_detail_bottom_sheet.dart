import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/workout/domain/models/exercise.dart';

class ExerciseDetailBottomSheet extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailBottomSheet({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                // Exercise name
                Text(
                  exercise.name,
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                // Exercise GIF
                if (exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty)
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 200.h,
                      margin: EdgeInsets.only(bottom: 20.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: CachedNetworkImage(
                          imageUrl: exercise.gifUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: AppColors.primary,
                              size: 64.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Exercise details grid
                _buildDetailRow(
                  Icons.accessibility_new,
                  'Body Part',
                  exercise.bodyPart,
                ),
                SizedBox(height: 12.h),
                _buildDetailRow(
                  Icons.my_location,
                  'Target Muscle',
                  exercise.target,
                ),
                SizedBox(height: 12.h),
                _buildDetailRow(
                  Icons.sports_gymnastics,
                  'Equipment',
                  exercise.equipment,
                ),
                if (exercise.secondaryMuscles.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    Icons.fitness_center,
                    'Secondary Muscles',
                    exercise.secondaryMuscles.join(', '),
                  ),
                ],
                SizedBox(height: 24.h),
                // Instructions
                Text(
                  'Instructions',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                if (exercise.instructions.isEmpty)
                  Text(
                    'No instructions available.',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                  )
                else
                  ...exercise.instructions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final instruction = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.black,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              instruction,
                              style: GoogleFonts.ubuntu(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
