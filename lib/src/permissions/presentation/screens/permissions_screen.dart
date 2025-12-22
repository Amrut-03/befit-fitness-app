import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';
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
    'Checking Health Connect',
    'Registering with Health Connect',
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

      // Step 2: Check if Health Connect is available
      _currentStep = 1;
      setState(() {
        _statusMessage = 'Checking Health Connect availability...';
      });
      
      final isHealthConnectAvailable = await _permissionService.isHealthConnectAvailable();
      if (!isHealthConnectAvailable) {
        setState(() {
          _statusMessage = 'Health Connect may not be installed. Please install it from Play Store.';
          _isLoading = false;
        });
        _showHealthConnectNotInstalledDialog();
        return;
      }
      
      // Step 3: Register with Health Connect first (critical step)
      _currentStep = 2;
      setState(() {
        _statusMessage = 'Registering app with Health Connect...';
      });
      
      // Try to register first - this is critical for Health Connect to recognize the app
      await _permissionService.tryRegisterWithHealthConnect();
      
      // Wait a moment for Health Connect to process
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Step 4: Request Health Connect permissions
      _currentStep = 3;
      setState(() {
        _statusMessage = 'Requesting Health Connect permissions...';
      });
      
      final healthConnectGranted = await _permissionService.requestHealthConnectPermissions();
      
      if (!healthConnectGranted) {
        setState(() {
          _statusMessage = 'Health Connect permissions need to be granted manually.';
          _isLoading = false;
        });
        _showHealthConnectManualDialog();
        return;
      }

      // Step 5: Verify connection to Health Connect
      _currentStep = 4;
      setState(() {
        _statusMessage = 'Verifying Health Connect connection...';
      });
      
      // Wait a moment before verification
      await Future.delayed(const Duration(milliseconds: 500));
      
      final connected = await _permissionService.connectToHealthConnect();
      
      if (connected) {
        setState(() {
          _statusMessage = 'All permissions granted! Connecting...';
        });
        
        // Wait a moment then navigate to home
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          context.go(HomePage.route);
        }
      } else {
        setState(() {
          _statusMessage = 'Please grant permissions manually in Health Connect.';
          _isLoading = false;
        });
        _showHealthConnectManualDialog();
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
              context.go(HomePage.route);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showHealthConnectNotInstalledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Health Connect Required'),
        content: const Text(
          'Health Connect is required to track your fitness data.\n\n'
          'Please install Health Connect from the Google Play Store:\n\n'
          '1. Tap "Open Play Store" below\n'
          '2. Install Health Connect\n'
          '3. Return to this app and try again\n\n'
          'Health Connect is Google\'s platform for managing health and fitness data.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _permissionService.openHealthConnect();
              // Wait and retry
              Future.delayed(const Duration(seconds: 2), () {
                _requestAllPermissions();
              });
            },
            child: const Text('Open Play Store'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(HomePage.route);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showHealthConnectManualDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Health Connect Setup'),
        content: const Text(
          'The app needs to be registered with Health Connect.\n\n'
          'IMPORTANT: Sometimes the app needs a device restart to appear in Health Connect.\n\n'
          'Try these steps:\n\n'
          '1. Tap "Try to Register" below\n'
          '2. If that doesn\'t work, tap "Open Health Connect"\n'
          '3. Go to "Data and access" > "App permissions"\n'
          '4. Look for "befit_fitness_app" or "Befit"\n'
          '5. If not found, restart your device and try again\n'
          '6. Grant permissions for:\n'
          '   - Steps\n'
          '   - Active energy burned',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _permissionService.tryRegisterWithHealthConnect();
              await _permissionService.openHealthConnect();
              // Wait and retry
              Future.delayed(const Duration(seconds: 3), () {
                _requestAllPermissions();
              });
            },
            child: const Text('Try to Register'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _permissionService.openHealthConnect();
            },
            child: const Text('Open Health Connect'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue anyway
              context.go(HomePage.route);
            },
            child: const Text('Skip'),
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
              context.go(HomePage.route);
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

