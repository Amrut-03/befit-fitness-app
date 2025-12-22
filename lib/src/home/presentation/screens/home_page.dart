import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/text_rich.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/animated_text_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/calculator_readings_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/calculator_values_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/home_card_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/search_widget.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/drawer_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/get_today_steps_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/get_fitness_data_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/usecase/request_permissions_usecase.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source.dart';
import 'package:befit_fitness_app/src/google_fit/data/datasources/google_fit_data_source_impl.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

/// Home page screen
class HomePage extends StatefulWidget {
  static const String route = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  double _scrollOffset = 0.0;
  double _scrollStep = 400.0;
  bool _scrollingForward = true;
  int _currentNavIndex = 0;
  int _steps = 0;
  double _calories = 0.0;
  double? _heartRate;

  String get _userEmail {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? '';
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    
    // Handle navigation based on index
    switch (index) {
      case 0:
        // Already on home
        break;
      case 2:
        // Navigate to More
        // TODO: Navigate to More screen
        break;
    }
  }

  void _onCenterButtonTapped() {
    // Center button expansion is handled by CustomBottomNavBar
    // This can be used for additional actions if needed
  }

  @override
  void initState() {
    super.initState();
    // Fetch home data when screen loads
    context.read<HomeBloc>().add(FetchHomeDataEvent(_userEmail));
    _startAutoScroll();
    _fetchFitnessData();
    _debugAllHealthData();
  }

  /// Debug method to show all health data in terminal
  Future<void> _debugAllHealthData() async {
    try {
      final dataSource = getIt<GoogleFitDataSource>();
      if (dataSource is GoogleFitDataSourceImpl) {
        await dataSource.debugAllHealthData();
      }
    } catch (e) {
      debugPrint('Error calling debug method: $e');
    }
  }

  Future<void> _fetchFitnessData() async {
    try {
      final repository = getIt<GoogleFitRepository>();
      
      // Check permissions first
      debugPrint('Google Fit: Checking current permissions...');
      final hasPermissionsResult = await repository.hasPermissions();
      bool hasPermissions = false;
      
      hasPermissionsResult.fold(
        (failure) {
          debugPrint('Google Fit: Permission check failed: ${failure.message}');
          hasPermissions = false;
        },
        (hasPerms) {
          hasPermissions = hasPerms;
          debugPrint('Google Fit: Current permissions status: $hasPerms');
        },
      );

      // If no permissions, try to request them
      if (!hasPermissions) {
        debugPrint('Google Fit: Attempting to request permissions...');
        debugPrint('Google Fit: This should open Health Connect permission screen...');
        final requestPermissionsUseCase = getIt<RequestPermissionsUseCase>();
        final permissionResult = await requestPermissionsUseCase();
        
        permissionResult.fold(
          (failure) {
            debugPrint('Google Fit: Permission request failed: ${failure.message}');
            // Show error dialog with instructions
            if (mounted) {
              _showHealthConnectSetupError(context);
            }
            hasPermissions = false;
          },
          (granted) {
            hasPermissions = granted;
            debugPrint('Google Fit: Permission request result: $granted');
            if (granted) {
              debugPrint('Google Fit: Permissions granted! Waiting 2 seconds before fetching data...');
              // Wait a bit for Health Connect to register the app
              Future.delayed(const Duration(seconds: 2), () {
                _fetchDataAfterPermissions();
              });
              return;
            }
          },
        );
      }

      // If we have permissions or if request failed, try to fetch data anyway
      if (hasPermissions) {
        _fetchDataAfterPermissions();
      } else {
        // Even if permission check failed, try direct fetch (sometimes it works)
        debugPrint('Google Fit: Trying direct fetch despite permission check failure...');
        _tryDirectDataFetch();
      }
    } catch (e, stackTrace) {
      debugPrint('Google Fit: Exception occurred: $e');
      debugPrint('Google Fit: Stack trace: $stackTrace');
      _tryDirectDataFetch();
    }
  }

  Future<void> _fetchDataAfterPermissions() async {
    try {
      // Get today's fitness data (includes both steps and calories)
      final getFitnessDataUseCase = getIt<GetFitnessDataUseCase>();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      debugPrint('Google Fit: Fetching data for date: $today');
      debugPrint('Google Fit: Date range: $startOfDay to $endOfDay');
      final fitnessDataResult = await getFitnessDataUseCase(today);
      
      fitnessDataResult.fold(
        (failure) {
          debugPrint('Google Fit: Failed to get fitness data: ${failure.message}');
          debugPrint('Google Fit: Failure type: ${failure.runtimeType}');
          // Try direct fetch as fallback
          _tryDirectDataFetch();
        },
        (fitnessData) {
          debugPrint('Google Fit: Data retrieved successfully!');
          debugPrint('Google Fit: Steps: ${fitnessData.steps}');
          debugPrint('Google Fit: Calories: ${fitnessData.calories}');
          debugPrint('Google Fit: Distance: ${fitnessData.distance}');
          debugPrint('Google Fit: Heart Rate: ${fitnessData.heartRate}');
          
          if (mounted) {
            setState(() {
              _steps = fitnessData.steps ?? 0;
              _calories = fitnessData.calories ?? 0.0;
              _heartRate = fitnessData.heartRate;
            });
            debugPrint('Google Fit: UI updated - Steps: $_steps, Calories: $_calories, Heart Rate: $_heartRate');
          }
        },
      );
    } catch (e) {
      debugPrint('Google Fit: Error in _fetchDataAfterPermissions: $e');
      _tryDirectDataFetch();
    }
  }

  void _showHealthConnectSetupError(BuildContext context) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Health Connect Registration Required'),
            content: const Text(
              'Your app needs to be registered with Health Connect to access fitness data.\n\n'
              'The app is not appearing in Health Connect because it hasn\'t been registered yet.\n\n'
              'Try this:\n\n'
              '1. Tap "Try to Register" below (this will attempt to register the app)\n'
              '2. If that doesn\'t work, tap "Open Health Connect"\n'
              '3. In Health Connect, go to "Data and access" > "App permissions"\n'
              '4. Look for "befit_fitness_app" or "Befit"\n'
              '5. If still not found, the app may need to request permissions while Health Connect is open\n\n'
              'After registering, return here and pull down to refresh.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Try to register by attempting to write data
                  await _tryRegisterWithHealthConnect();
                  // Wait a bit then try again
                  Future.delayed(const Duration(seconds: 3), () {
                    _fetchFitnessData();
                  });
                },
                child: const Text('Try to Register'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openHealthConnect();
                },
                child: const Text('Open Health Connect'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Try to register app with Health Connect by attempting to write data
  /// This sometimes triggers Health Connect to register the app
  Future<void> _tryRegisterWithHealthConnect() async {
    try {
      debugPrint('Attempting to register app with Health Connect by writing data...');
      final health = getIt<Health>();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(hours: 1));
      
      // Try to write a small amount of steps data
      // This might trigger Health Connect to register the app
      try {
        await health.writeHealthData(
          value: 0.0, // Write 0 steps as a test
          type: HealthDataType.STEPS,
          unit: HealthDataUnit.COUNT,
          startTime: startOfDay,
          endTime: endOfDay,
        );
        debugPrint('Successfully wrote test data - app may be registered now');
      } catch (e) {
        debugPrint('Write attempt failed (may trigger registration): $e');
        // Even if write fails, it might have triggered Health Connect to register the app
      }
      
      // Also try to request permissions again after write attempt
      try {
        const types = [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ];
        final granted = await health.requestAuthorization(types);
        debugPrint('Permission request after write attempt: $granted');
      } catch (e) {
        debugPrint('Permission request after write failed: $e');
      }
    } catch (e) {
      debugPrint('Error trying to register with Health Connect: $e');
    }
  }

  /// Open Health Connect app
  Future<void> _openHealthConnect() async {
    try {
      if (Platform.isAndroid) {
        const packageName = 'com.google.android.apps.healthdata';
        
        // Try multiple methods to open Health Connect
        
        // Method 1: Try to open Health Connect's app permissions screen directly
        try {
          // Health Connect's app permissions intent
          final intentUri = Uri.parse('android-app://$packageName/healthconnect.permission');
          if (await canLaunchUrl(intentUri)) {
            await launchUrl(intentUri, mode: LaunchMode.externalApplication);
            debugPrint('Opened Health Connect permissions screen');
            return;
          }
        } catch (e) {
          debugPrint('Could not open Health Connect permissions screen: $e');
        }
        
        // Method 2: Try to open Health Connect app directly
        try {
          final uri = Uri.parse('android-app://$packageName');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint('Opened Health Connect app');
            return;
          }
        } catch (e) {
          debugPrint('Could not open Health Connect directly: $e');
        }
        
        // Method 3: Try to open via Play Store if not installed
        try {
          final playStoreUri = Uri.parse('market://details?id=$packageName');
          if (await canLaunchUrl(playStoreUri)) {
            await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
            debugPrint('Opened Health Connect in Play Store');
            return;
          }
        } catch (e) {
          debugPrint('Could not open Play Store: $e');
        }
        
        // Fallback to app settings
        await _openAppSettings();
      }
    } catch (e) {
      debugPrint('Error opening Health Connect: $e');
      // Fallback to app settings
      await _openAppSettings();
    }
  }

  /// Open app settings where user can grant permissions
  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
      debugPrint('Opened app settings');
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// Try to fetch data directly using the health package
  Future<void> _tryDirectDataFetch() async {
    try {
      debugPrint('Google Fit: Trying direct data fetch...');
      final health = getIt<Health>();
      
      // Use UTC to avoid timezone issues, and try a wider date range
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      // Try last 7 days to see if we can get any data
      final startDate = today.subtract(const Duration(days: 7));
      final endDate = today.add(const Duration(days: 1));
      
      debugPrint('Google Fit: Direct fetch - Start (UTC): $startDate, End (UTC): $endDate');
      debugPrint('Google Fit: Direct fetch - Local time: ${DateTime.now()}');
      
      // Try to get steps with wider range first
      try {
        final stepsData = await health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startDate,
          endTime: endDate,
        );
        debugPrint('Google Fit: Direct fetch - Steps data count: ${stepsData.length}');
        
        if (stepsData.isNotEmpty) {
          // Filter to today's data only
          final todayStart = DateTime.utc(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));
          
          int totalSteps = 0;
          int todaySteps = 0;
          
          for (var step in stepsData) {
            final value = (step.value as NumericHealthValue).numericValue.toInt();
            totalSteps += value;
            
            // Check if this entry is from today
            if (step.dateFrom.isAfter(todayStart) && step.dateFrom.isBefore(todayEnd)) {
              todaySteps += value;
              debugPrint('Google Fit: Today step entry - Value: $value, Date: ${step.dateFrom} to ${step.dateTo}');
            } else {
              debugPrint('Google Fit: Other day step entry - Value: $value, Date: ${step.dateFrom} to ${step.dateTo}');
            }
          }
          
          debugPrint('Google Fit: Direct fetch - Total steps (7 days): $totalSteps');
          debugPrint('Google Fit: Direct fetch - Today steps: $todaySteps');
          
          if (mounted) {
            setState(() {
              _steps = todaySteps > 0 ? todaySteps : totalSteps;
            });
          }
        } else {
          debugPrint('Google Fit: Direct fetch - No steps data found in 7-day range');
          // Show message to user about Health Connect permissions
          if (mounted) {
            _showHealthConnectPermissionGuide(context);
          }
        }
      } catch (e) {
        debugPrint('Google Fit: Direct fetch steps error: $e');
        if (mounted) {
          _showHealthConnectPermissionGuide(context);
        }
      }
      
      // Try to get calories with wider range
      try {
        final caloriesData = await health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: startDate,
          endTime: endDate,
        );
        debugPrint('Google Fit: Direct fetch - Calories data count: ${caloriesData.length}');
        
        if (caloriesData.isNotEmpty) {
          // Filter to today's data only
          final todayStart = DateTime.utc(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));
          
          double totalCalories = 0;
          double todayCalories = 0;
          
          for (var cal in caloriesData) {
            final value = (cal.value as NumericHealthValue).numericValue.toDouble();
            totalCalories += value;
            
            // Check if this entry is from today
            if (cal.dateFrom.isAfter(todayStart) && cal.dateFrom.isBefore(todayEnd)) {
              todayCalories += value;
              debugPrint('Google Fit: Today calorie entry - Value: $value, Date: ${cal.dateFrom} to ${cal.dateTo}');
            } else {
              debugPrint('Google Fit: Other day calorie entry - Value: $value, Date: ${cal.dateFrom} to ${cal.dateTo}');
            }
          }
          
          debugPrint('Google Fit: Direct fetch - Total calories (7 days): $totalCalories');
          debugPrint('Google Fit: Direct fetch - Today calories: $todayCalories');
          
          if (mounted) {
            setState(() {
              _calories = todayCalories > 0 ? todayCalories : totalCalories;
            });
          }
        } else {
          debugPrint('Google Fit: Direct fetch - No calories data found in 7-day range');
        }
      } catch (e) {
        debugPrint('Google Fit: Direct fetch calories error: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Google Fit: Direct fetch exception: $e');
      debugPrint('Google Fit: Direct fetch stack trace: $stackTrace');
    }
  }

  void _showHealthConnectPermissionGuide(BuildContext context) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Health Connect Setup Required'),
            content: const Text(
              'Your app needs to be registered with Health Connect first.\n\n'
              'Please follow these steps:\n\n'
              '1. Open the "Health Connect" app\n'
              '2. Tap the menu (☰) or "Data and access"\n'
              '3. Tap "App permissions" or "Manage permissions"\n'
              '4. Look for "Befit" or tap "See all apps"\n'
              '5. If not found, try requesting permissions again in this app\n\n'
              'OR manually:\n'
              '1. Open Health Connect\n'
              '2. Go to Settings > App permissions\n'
              '3. Grant access when prompted\n\n'
              'After granting, return here and pull down to refresh.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Try to request permissions again
                  _fetchFitnessData();
                },
                child: const Text('Try Again'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showPermissionError(BuildContext context) {
    // Show a dialog to inform user about permissions
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Please grant health data permissions to view your steps and calories.\n\n'
              'Go to:\n'
              'Settings > Apps > Befit > Permissions\n\n'
              'Enable:\n'
              '- Physical activity\n'
              '- Body sensors\n'
              '- Health Connect (if available)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showHealthConnectError(BuildContext context) {
    // Show a dialog to inform user about Health Connect
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Health Connect Required'),
            content: const Text(
              'To access your fitness data, you need Health Connect installed.\n\n'
              '1. Install "Health Connect by Google" from Play Store\n'
              '2. Open Health Connect and connect Google Fit\n'
              '3. Grant permissions when prompted\n\n'
              'After installing, restart the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

        if (_scrollOffset >= maxScrollExtent) {
          _scrollingForward = false;
        } else if (_scrollOffset <= 0) {
          _scrollingForward = true;
        }

        _scrollOffset += _scrollingForward ? _scrollStep : -_scrollStep;
        _scrollOffset = _scrollOffset.clamp(0.0, maxScrollExtent);

        _scrollController.animateTo(
          _scrollOffset,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }



  void _showQuickWorkoutOptions(BuildContext context) {
    final quickWorkoutInfo = {
      'Core Crusher': {
        'duration': '15 min',
        'level': 'Beginner',
        'exercises': '11',
        'calories': '70-80',
        'folder': 'core_crusher',
      },
      'Full Body Workout': {
        'duration': '20 min',
        'level': 'Intermediate',
        'exercises': '15',
        'calories': '120-130',
        'folder': 'full_body_hiit',
      },
      'Upper Body Strength': {
        'duration': '30 min',
        'level': 'Advanced',
        'exercises': '20',
        'calories': '150-180',
        'folder': 'upper_body',
      },
    };

    showModalBottomSheet(
      backgroundColor: Colors.black,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Choose a Quick Workout',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              ListView.builder(
                itemCount: quickWorkoutInfo.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final workoutName = quickWorkoutInfo.keys.elementAt(index);
                  final workoutDetails = quickWorkoutInfo[workoutName]!;

                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            workoutName,
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            '${workoutDetails['duration']} | ${workoutDetails['level']} | ${workoutDetails['exercises']} Exercises',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onTap: () {
                            // TODO: Navigate to workout details
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is Unauthenticated) {
              // Navigate to login page when user logs out
              context.go(LoginPage.route);
            }
          },
        ),
      ],
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            backgroundColor: AppColors.primary,
            color: Colors.black,
            onRefresh: () async {
              context.read<HomeBloc>().add(RefreshHomeDataEvent(_userEmail));
              await _fetchFitnessData();
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              drawer: state is HomeLoaded
                  ? HomeDrawer(state: state)
                  : null,
              bottomNavigationBar: state is HomeLoaded
                  ? CustomBottomNavBar(
                      currentIndex: _currentNavIndex,
                      onTap: _onNavItemTapped,
                      onCenterButtonTap: _onCenterButtonTapped,
                    )
                  : null,
              body: state is HomeLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : state is HomeError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${state.message}',
                            style: GoogleFonts.ubuntu(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton(
                            onPressed: () {
                              context.read<HomeBloc>().add(
                                FetchHomeDataEvent(_userEmail),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : state is HomeLoaded
                  ? _buildHomeContent(context, state)
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    final healthPercentages = state.healthMetrics.calculateHealthPercentages();
    final bmiPercentage = healthPercentages['BMI']!;
    final bmrPercentage = healthPercentages['BMR']!;
    final hrcPercentage = healthPercentages['HRC']!;

    final maxPercentage = [
      bmiPercentage,
      bmrPercentage,
      hrcPercentage,
    ].reduce((a, b) => a > b ? a : b);

    const double baseRadius = 10.0;
    const double maxRadius = 40.0;

    final bmiRadius =
        baseRadius +
        ((bmiPercentage / maxPercentage) * (maxRadius - baseRadius));
    final bmrRadius =
        baseRadius +
        ((bmrPercentage / maxPercentage) * (maxRadius - baseRadius));
    final hrcRadius =
        baseRadius +
        ((hrcPercentage / maxPercentage) * (maxRadius - baseRadius));

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 235.h,
              width: 370.w,
              child: Stack(
                children: [
                  // Menu button to open drawer
                  Positioned(
                    top: 30,
                    left: 0,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.black,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(height: 65.h),
                      Container(
                        height: 150.h,
                        width: 300.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Stack(
                          children: [
                            // Decorative circle SVG
                            Positioned(
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: SvgPicture.asset(
                                  'assets/svg/circle.svg',
                                  color: Colors.black.withOpacity(0.3),
                                  width: 300.w,
                                  height: 150.h,
                                  placeholderBuilder: (context) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Image.asset(
                                'assets/home/images/design.png',
                                height: 80,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(10.w),
                              child: Row(
                                children: [
                                  CustomTextRich(
                                    text1: 'Hi, ',
                                    textColor1: Colors.black,
                                    fontWeight1: FontWeight.w500,
                                    fontSize1: 20.sp,
                                    text2:
                                        '${state.userProfile.firstName ?? "User"} 👋',
                                    textColor2: Colors.black,
                                    fontWeight2: FontWeight.bold,
                                    fontSize2: 20.sp,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20.h,
                    right: -15.w,
                    child: SizedBox(
                      height: 200.h,
                      width: 200.w,
                      child: Image.asset('assets/home/images/model.png'),
                    ),
                  ),
                ],
              ),
            ),
            const AnimatedTextWidget(),
            SizedBox(height: 10.h),
            SearchWidget(
              email: _userEmail,
              onCategorySelected: (category) {
                // TODO: Handle category selection navigation
              },
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 250.h,
                      width: 230.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primaryDark,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: Colors.black87,
                                value: bmiPercentage,
                                radius: bmiRadius.r,
                                title: '${bmiPercentage.toStringAsFixed(0)}%',
                                titleStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.black54,
                                value: bmrPercentage,
                                radius: bmrRadius.r,
                                title: '${bmrPercentage.toStringAsFixed(0)}%',
                                titleStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.black26,
                                value: hrcPercentage,
                                radius: hrcRadius.r,
                                title: '${hrcPercentage.toStringAsFixed(0)}%',
                                titleStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100.h,
                      left: 80.w,
                      child: Column(
                        children: [
                          Text(
                            state.healthMetrics.overallHealthPercentage != null
                                ? state.healthMetrics.overallHealthPercentage!
                                      .toStringAsFixed(0)
                                : '0',
                            style: GoogleFonts.ubuntu(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                            ),
                          ),
                          Text(
                            'of 100%',
                            style: GoogleFonts.ubuntu(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10.h,
                      left: 40.w,
                      child: Text(
                        'Overall Health',
                        style: GoogleFonts.ubuntu(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const CalculatorValuesWidget(),
                  ],
                ),
                SizedBox(width: 10.w),
                CalculatorReadingsWidget(
                  onClick: () {
                    // TODO: Navigate to health calculators
                  },
                  steps: _steps,
                  calories: _calories,
                  heartRate: _heartRate,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              "See All",
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  HomeCardWidget(
                    mainImage: 'assets/home/images/workout1.jpg',
                    title: 'Quick Workout Tutorials',
                    desc:
                        'Need a quick workout? Try our Pre-mode workout plans.',
                    onClick: () => _showQuickWorkoutOptions(context),
                    buttonText: 'Start Workout',
                    modelImage: 'assets/home/images/girl.png',
                    height: 160.h,
                    width: 160.w,
                    left: 130.w,
                    bottom: 40.h,
                  ),
                  HomeCardWidget(
                    mainImage: 'assets/home/images/workout.jpg',
                    title: 'Generate Workout Plans',
                    desc:
                        'Create a personalized workout plan tailored to your goals and experience level.',
                    onClick: () {
                      // TODO: Navigate to generate workout
                    },
                    buttonText: 'Start to Generate',
                    modelImage: 'assets/home/images/workout2.png',
                    height: 210.h,
                    width: 90.w,
                    left: 200.w,
                    bottom: 20.h,
                  ),
                  HomeCardWidget(
                    mainImage: 'assets/home/images/workout.jpg',
                    title: 'Generate Diet Plans',
                    desc:
                        'Create a personalized nutrition plan tailored to your dietary needs and health goals.',
                    onClick: () {
                      // TODO: Navigate to generate diet plan
                    },
                    buttonText: 'Get Diet Plan',
                    modelImage: 'assets/home/images/model.png',
                    height: 140.h,
                    width: 140.w,
                    left: 150.w,
                    bottom: 70.h,
                  ),
                  HomeCardWidget(
                    mainImage: 'assets/home/images/workout1.jpg',
                    title: 'Health CalCulators',
                    desc:
                        'Develop a personalized set of health calculators to track your fitness metrics.',
                    onClick: () {
                      // TODO: Navigate to health calculators
                    },
                    buttonText: 'Calculate health',
                    modelImage: 'assets/home/images/workout3.png',
                    height: 150.h,
                    width: 150.w,
                    left: 150.w,
                    bottom: 50.h,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

