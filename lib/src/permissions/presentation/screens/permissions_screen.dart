import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';
import 'package:befit_fitness_app/src/profile_onboarding/data/repositories/user_profile_repository_impl.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/home_page.dart';

class PermissionsScreen extends StatefulWidget {
  static const String route = '/permissions';
  
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  String _statusMessage = 'Requesting permissions...';
  int _currentStep = 0;
  final List<String> _steps = [
    'Android Permissions',
    'Checking Google Fit',
    'Registering with Google Fit',
    'Requesting Permissions',
    'Verifying Connection',
  ];

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
      _statusMessage = 'Requesting Android permissions...';
    });

    try {
      // Step 1: Request Android permissions using permission_handler
      _currentStep = 0;
      setState(() {
        _statusMessage = 'Requesting Body Sensors permission...';
      });
      
      final androidPermissionsGranted = await _permissionService.requestAndroidPermissions();
      
      if (!androidPermissionsGranted) {
        setState(() {
          _statusMessage = 'Some Android permissions were denied. Please grant them in Settings.';
          _isLoading = false;
        });
        _showPermissionDeniedDialog();
        return;
      }

      // Step 2: Check if Google Fit is available
      _currentStep = 1;
      setState(() {
        _statusMessage = 'Checking Google Fit availability...';
      });
      
      // Step 3: Request Google Fit permissions
      _currentStep = 2;
      setState(() {
        _statusMessage = 'Requesting Google Fit permissions...';
      });
      
      // This will use Google Fit OAuth to request permissions
      final googleFitGranted = await _permissionService.requestGoogleFitPermissions();
      
      if (!googleFitGranted) {
        setState(() {
          _statusMessage = 'Google Fit setup failed. Please try again.';
          _isLoading = false;
        });
        // Check if Google Fit is available
        final isAvailable = await _permissionService.isGoogleFitAvailable();
        if (!isAvailable) {
          _showGoogleFitNotInstalledDialog();
        } else {
          _showGoogleFitManualDialog();
        }
        return;
      }

      // Step 5: Verify connection to Google Fit
      _currentStep = 4;
      setState(() {
        _statusMessage = 'Verifying Google Fit connection...';
      });
      
      // Wait a moment before verification
      await Future.delayed(const Duration(milliseconds: 500));
      
      final connected = await _permissionService.connectToGoogleFit();
      
      if (connected) {
        setState(() {
          _statusMessage = 'All permissions granted! Connecting...';
        });
        
        // Wait a moment then navigate to home
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          // Verify profile is complete before navigating (should be true at this point)
          // This ensures the router won't redirect us back to onboarding
          final profileRepository = getIt<UserProfileRepository>();
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Retry checking profile completion to ensure it's saved
            bool isComplete = false;
            for (int i = 0; i < 5; i++) {
              await Future.delayed(const Duration(milliseconds: 200));
              isComplete = await profileRepository.isProfileComplete(firebaseUser.uid);
              if (isComplete) break;
            }
            
            // Navigate to home with query parameter to indicate we're coming from permissions
            // Even if check fails, navigate anyway since we know profile should be complete
            context.go('${HomePage.route}?fromPermissions=true');
          } else {
            context.go('${HomePage.route}?fromPermissions=true');
          }
        }
      } else {
        setState(() {
          _statusMessage = 'Please grant permissions manually in Google Fit.';
          _isLoading = false;
        });
        _showGoogleFitManualDialog();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error requesting permissions: $e';
        _isLoading = false;
      });
      _showErrorDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Please grant all permissions to use the app.\n\n'
          'Go to Settings > Apps > Befit > Permissions and enable:\n'
          '- Body sensors\n'
          '- Physical activity\n'
          '- Location (optional)',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _permissionService.openAppSettings();
              // Retry after user returns
              Future.delayed(const Duration(seconds: 2), () {
                _requestAllPermissions();
              });
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue anyway
              context.go('${HomePage.route}?fromPermissions=true');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showGoogleFitNotInstalledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Google Fit Required'),
        content: const Text(
          'Google Fit is required to track your fitness data.\n\n'
          'Please ensure Google Play Services is installed and up to date.\n\n'
          'Google Fit uses Google Play Services to access your health data.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try requesting permissions again (Google Fit OAuth)
              _requestAllPermissions();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('${HomePage.route}?fromPermissions=true');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showGoogleFitManualDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Grant Google Fit Permissions'),
        content: const Text(
          'The app uses Google Fit to access your health data.\n\n'
          'Please follow these steps:\n\n'
          '1. Tap "Grant Permissions" below\n'
          '2. Sign in with your Google account if prompted\n'
          '3. Grant permissions for:\n'
          '   • Steps (read & write)\n'
          '   • Active energy burned (read & write)\n'
          '   • Distance (read & write)\n'
          '   • Heart rate (read & write)\n'
          '4. Return to this app and tap "Check Permissions"\n\n'
          'Note: This uses Google Fit OAuth for authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Request Google Fit permissions (OAuth)
              setState(() {
                _isLoading = true;
                _statusMessage = 'Requesting Google Fit permissions...';
              });
              final granted = await _permissionService.requestGoogleFitPermissions();
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                if (granted) {
                  // Permissions granted, check connection
                  _requestAllPermissions();
                } else {
                  // Show check dialog
                  _showCheckPermissionsDialog();
                }
              }
            },
            child: const Text('Grant Permissions'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Check if permissions are now granted
              setState(() {
                _isLoading = true;
                _statusMessage = 'Checking permissions...';
              });
              
              final areGranted = await _permissionService.areAllPermissionsGranted();
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                
                if (areGranted) {
                  // Permissions granted, continue
                  _requestAllPermissions();
                } else {
                  // Still not granted, show manual dialog again
                  _showGoogleFitManualDialog();
                }
              }
            },
            child: const Text('Check Permissions'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue anyway
              context.go('${HomePage.route}?fromPermissions=true');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showCheckPermissionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Check Permissions'),
        content: const Text(
          'Have you granted permissions in Google Fit?\n\n'
          'Tap "Yes" to verify, or "No" to try again.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Check if permissions are now granted
              setState(() {
                _isLoading = true;
                _statusMessage = 'Checking permissions...';
              });
              
              final areGranted = await _permissionService.areAllPermissionsGranted();
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                
                if (areGranted) {
                  // Permissions granted, continue with connection
                  setState(() {
                    _statusMessage = 'Permissions granted! Verifying connection...';
                    _isLoading = true;
                  });
                  
                  final connected = await _permissionService.connectToGoogleFit();
                  
                  if (mounted) {
                    if (connected) {
                      setState(() {
                        _statusMessage = 'All permissions granted! Connecting...';
                      });
                      
                      await Future.delayed(const Duration(seconds: 1));
                      
                      if (mounted) {
                        context.go('${HomePage.route}?fromPermissions=true');
                      }
                    } else {
                      setState(() {
                        _statusMessage = 'Please grant all required permissions.';
                        _isLoading = false;
                      });
                      _showGoogleFitManualDialog();
                    }
                  }
                } else {
                  // Still not granted
                  _showGoogleFitManualDialog();
                }
              }
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try requesting permissions again
              _requestAllPermissions();
            },
            child: const Text('No, Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(_statusMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestAllPermissions();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('${HomePage.route}?fromPermissions=true');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or logo
              Icon(
                Icons.fitness_center,
                size: 80.w,
                color: AppColors.primary,
              ),
              SizedBox(height: 30.h),
              
              // Title
              Text(
                'Permissions Required',
                style: GoogleFonts.ubuntu(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              
              // Description
              Text(
                'To track your fitness data, we need the following permissions:',
                style: GoogleFonts.ubuntu(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              
              // Steps indicator
              ...List.generate(_steps.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? AppColors.primary
                                  : Colors.grey,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.ubuntu(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Text(
                          _steps[index],
                          style: GoogleFonts.ubuntu(
                            fontSize: 16.sp,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? AppColors.textPrimary : Colors.grey,
                          ),
                        ),
                      ),
                      if (isActive && _isLoading)
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              
              SizedBox(height: 40.h),
              
              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const Spacer(),
              
              // Retry button (if failed)
              if (!_isLoading)
                ElevatedButton(
                  onPressed: _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

