import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/camera_permission_service.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/widgets/user_education_bottom_sheet.dart';

/// Widget to handle camera permission states and show appropriate UI
class CameraPermissionWidget extends StatelessWidget {
  final CameraPermissionStatus status;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onPickFromGallery;
  final VoidCallback? onShowEducation;

  const CameraPermissionWidget({
    super.key,
    required this.status,
    this.onRequestPermission,
    this.onOpenSettings,
    this.onPickFromGallery,
    this.onShowEducation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon based on status
                _buildStatusIcon(),
                SizedBox(height: 24.h),
                
                // Title
                Text(
                  _getTitle(),
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                
                // Description
                Text(
                  _getDescription(),
                  style: GoogleFonts.ubuntu(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                
                // Action buttons
                ..._buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    
    switch (status) {
      case CameraPermissionStatus.denied:
      case CameraPermissionStatus.permanentlyDenied:
        icon = Icons.camera_alt_outlined;
        color = Colors.orange;
        break;
      case CameraPermissionStatus.hardwareUnavailable:
        icon = Icons.camera_alt_outlined;
        color = Colors.red;
        break;
      case CameraPermissionStatus.restricted:
        icon = Icons.lock_outline;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64.sp,
        color: color,
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case CameraPermissionStatus.denied:
        return 'Camera Permission Required';
      case CameraPermissionStatus.permanentlyDenied:
        return 'Camera Permission Denied';
      case CameraPermissionStatus.hardwareUnavailable:
        return 'Camera Not Available';
      case CameraPermissionStatus.restricted:
        return 'Camera Restricted';
      default:
        return 'Camera Access Issue';
    }
  }

  String _getDescription() {
    switch (status) {
      case CameraPermissionStatus.denied:
        return 'We need camera access to scan barcodes. Please grant permission to continue.';
      case CameraPermissionStatus.permanentlyDenied:
        return 'Camera permission has been permanently denied. Please enable it in app settings.';
      case CameraPermissionStatus.hardwareUnavailable:
        return 'Your device doesn\'t have a camera or it\'s not available. You can still scan barcodes from your gallery.';
      case CameraPermissionStatus.restricted:
        return 'Camera access is restricted on your device. Please check your device settings.';
      default:
        return 'Unable to access camera. Please try again or use gallery option.';
    }
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];
    
    // Info/Education button
    if (onShowEducation != null) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const UserEducationBottomSheet(),
            );
            onShowEducation?.call();
          },
          icon: Icon(Icons.info_outline, color: AppColors.primary),
          label: Text(
            'Learn More',
            style: GoogleFonts.ubuntu(
              color: AppColors.primary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
            side: BorderSide(color: AppColors.primary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      );
      buttons.add(SizedBox(height: 12.h));
    }
    
    // Request permission button
    if (status == CameraPermissionStatus.denied && onRequestPermission != null) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRequestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Grant Permission',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      buttons.add(SizedBox(height: 12.h));
    }
    
    // Open settings button
    if (status == CameraPermissionStatus.permanentlyDenied && onOpenSettings != null) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onOpenSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      buttons.add(SizedBox(height: 12.h));
    }
    
    // Gallery fallback button (always show if available)
    if (onPickFromGallery != null) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPickFromGallery,
            icon: Icon(Icons.photo_library, color: Colors.white70),
            label: Text(
              'Pick from Gallery',
              style: GoogleFonts.ubuntu(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              side: BorderSide(color: Colors.white24, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      );
    }
    
    return buttons;
  }
}

