import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Model for activity data
class Activity {
  final String name;
  final IconData icon;
  final Color color;

  const Activity({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Reusable widget for displaying a single activity item
class ActivityItem extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityItem({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activity.color.withOpacity(0.2),
              border: Border.all(
                color: activity.color,
                width: 2,
              ),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: 70.w,
            child: Text(
              activity.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ubuntu(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

