import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activity_item.dart';

/// Widget displaying various activities in a horizontal scrollable list
class ActivitiesTile extends StatelessWidget {
  final List<Activity> activities;
  final VoidCallback? onMoreTap;
  final Function(Activity)? onActivityTap;

  const ActivitiesTile({
    super.key,
    required this.activities,
    this.onMoreTap,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Exerciing Activities",
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...activities.map((activity) => Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: ActivityItem(
                              activity: activity,
                              onTap: () => onActivityTap?.call(activity),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

