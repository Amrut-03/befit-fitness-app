import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/animated_text_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/calculator_readings_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/overall_health_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activities_tile.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activity_item.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/health_metrics_chart.dart';
import 'package:befit_fitness_app/src/activity_tracking/presentation/screens/activity_tracking_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/drawer_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/discover_section.dart';
import 'package:befit_fitness_app/src/permissions/presentation/services/permission_service.dart';
import 'package:befit_fitness_app/src/permissions/presentation/screens/permissions_screen.dart';

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
  bool _arePermissionsGranted = false;
  bool _isCheckingPermissions = true;

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
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
    _startAutoScroll();
    _checkPermissions();
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // First fetch home data, then fitness data will be fetched after state is loaded
        context.read<HomeBloc>().add(FetchHomeDataEvent(_userId));
        // Add a small delay to ensure HomeLoaded state is emitted first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.read<HomeBloc>().add(const FetchFitnessDataEvent());
          }
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });
    
    try {
      final permissionService = PermissionService();
      final areGranted = await permissionService.areAllPermissionsGranted();
      
      if (mounted) {
        setState(() {
          _arePermissionsGranted = areGranted;
          _isCheckingPermissions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _arePermissionsGranted = false;
          _isCheckingPermissions = false;
        });
      }
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
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded && state.fitnessData == null && !state.isFetchingFitnessData) {
            context.read<HomeBloc>().add(const FetchFitnessDataEvent());
          }
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
          return RefreshIndicator(
            backgroundColor: AppColors.primary,
            color: Colors.black,
            onRefresh: () async {
              if (mounted) {
                context.read<HomeBloc>().add(RefreshHomeDataEvent(_userId));
                context.read<HomeBloc>().add(const FetchFitnessDataEvent());
              }
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
                              if (mounted) {
                                context.read<HomeBloc>().add(
                                  FetchHomeDataEvent(_userId),
                                );
                              }
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
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {

    final fitnessData = state.fitnessData;
    final steps = fitnessData?.steps ?? 0;
    final calories = fitnessData?.calories ?? 0.0;
    final moveMin = fitnessData?.moveMin;
    
    final stepsPercentage = (steps / 10000 * 100).clamp(0.0, 100.0);
    final caloriesPercentage = (calories / 2000 * 100).clamp(0.0, 100.0);
    final moveMinPercentage = (moveMin != null ? (moveMin / 30 * 100) : 0.0).clamp(0.0, 100.0);

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              const AnimatedTextWidget(),
              SizedBox(height: 20.h),
              // Show Google Fit connection banner if permissions are not granted
              if (!_isCheckingPermissions && !_arePermissionsGranted) ...[
                _buildGoogleFitBanner(context),
                SizedBox(height: 16.h),
              ],
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OverallHealthWidget(
                    // containerWidth: 250.w, 
                    stepsPercentage: stepsPercentage,
                    caloriesPercentage: caloriesPercentage,
                    moveMinPercentage: moveMinPercentage,
                    overallHealthPercentage: state.healthMetrics.overallHealthPercentage,
                    backgroundColor: Colors.black,
                  ),
                  SizedBox(width: 10.w),
                  CalculatorReadingsWidget(
                    onClick: () {
                      // TODO: Navigate to health calculators
                    },
                    steps: steps,
                    calories: calories,
                    moveMin: moveMin,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ActivitiesTile(
                activities: _getActivities(),
                onMoreTap: () {
                  // TODO: Navigate to more activities screen
                },
                onActivityTap: (activity) {
                  context.push(
                    ActivityTrackingScreen.route,
                    extra: activity,
                  );
                },
              ),
              SizedBox(
                height: 300.h,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40.w,
                        child: HealthMetricsChart(
                          title: 'Weight Track',
                          subtitle: 'Weight (kg)',
                          chartType: ChartType.weight,
                          isWeekly: true,
                          series: _getWeightChartData(),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40.w,
                        child: HealthMetricsChart(
                          title: 'Calories Burn Track',
                          subtitle: 'Calories',
                          chartType: ChartType.calories,
                          isWeekly: true,
                          series: _getCaloriesChartData(),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40.w,
                        child: HealthMetricsChart(
                          title: 'Sleep Track',
                          subtitle: 'Sleep (hrs)',
                          chartType: ChartType.sleep,
                          isWeekly: true,
                          series: _getSleepChartData(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Discover Features",
                style: GoogleFonts.ubuntu(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16.h),
              DiscoverSection(
                onCardTap: (cardName) {
                  if (cardName == 'Bar Code Scanner') {
                    context.push(BarcodeScannerScreen.route);
                  }
                  // Handle other card taps here
                },
              ),
              SizedBox(height: 20.h),
              // Text(
              //   "See All",
              //   style: GoogleFonts.ubuntu(
              //     color: Colors.black,
              //     fontSize: 20,
              //     fontWeight: FontWeight.w800,
              //     decoration: TextDecoration.underline,
              //   ),
              // ),
              // SingleChildScrollView(
              //   controller: _scrollController,
              //   scrollDirection: Axis.horizontal,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.start,
              //     children: [
              //       HomeCardWidget(
              //         mainImage: 'assets/home/images/workout1.jpg',
              //         title: 'Quick Workout Tutorials',
              //         desc:
              //             'Need a quick workout? Try our Pre-mode workout plans.',
              //         onClick: () => _showQuickWorkoutOptions(context),
              //         buttonText: 'Start Workout',
              //         modelImage: 'assets/home/images/girl.png',
              //         height: 160.h,
              //         width: 160.w,
              //         left: 130.w,
              //         bottom: 40.h,
              //       ),
              //       HomeCardWidget(
              //         mainImage: 'assets/home/images/workout.jpg',
              //         title: 'Generate Workout Plans',
              //         desc:
              //             'Create a personalized workout plan tailored to your goals and experience level.',
              //         onClick: () {
              //           // TODO: Navigate to generate workout
              //         },
              //         buttonText: 'Start to Generate',
              //         modelImage: 'assets/home/images/workout2.png',
              //         height: 210.h,
              //         width: 90.w,
              //         left: 200.w,
              //         bottom: 20.h,
              //       ),
              //       HomeCardWidget(
              //         mainImage: 'assets/home/images/workout.jpg',
              //         title: 'Generate Diet Plans',
              //         desc:
              //             'Create a personalized nutrition plan tailored to your dietary needs and health goals.',
              //         onClick: () {
              //           // TODO: Navigate to generate diet plan
              //         },
              //         buttonText: 'Get Diet Plan',
              //         modelImage: 'assets/home/images/model.png',
              //         height: 140.h,
              //         width: 140.w,
              //         left: 150.w,
              //         bottom: 70.h,
              //       ),
              //       HomeCardWidget(
              //         mainImage: 'assets/home/images/workout1.jpg',
              //         title: 'Health CalCulators',
              //         desc:
              //             'Develop a personalized set of health calculators to track your fitness metrics.',
              //         onClick: () {
              //           // TODO: Navigate to health calculators
              //         },
              //         buttonText: 'Calculate health',
              //         modelImage: 'assets/home/images/workout3.png',
              //         height: 150.h,
              //         width: 150.w,
              //         left: 150.w,
              //         bottom: 50.h,
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get list of available activities
  List<Activity> _getActivities() {
    return const [
      Activity(
        name: 'Walking',
        icon: Icons.directions_walk,
        color: Color(0xFF2196F3),
      ),
      Activity(
        name: 'Running',
        icon: Icons.directions_run,
        color: Color(0xFF4CAF50),
      ),
      Activity(
        name: 'Cycling',
        icon: Icons.directions_bike,
        color: Color(0xFFFF9800),
      ),
      Activity(
        name: 'Hiking',
        icon: Icons.terrain,
        color: Color(0xFF795548),
      ),
      Activity(
        name: 'Swimming',
        icon: Icons.pool,
        color: Color(0xFF00BCD4),
      ),
      Activity(
        name: 'Skating',
        icon: Icons.skateboarding,
        color: Color(0xFFE91E63),
      ),
    ];
  }

  /// Get Monday of current week
  DateTime _getMondayOfWeek(DateTime date) {
    // weekday: 1 = Monday, 7 = Sunday
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  /// Get weight chart data
  ChartSeries _getWeightChartData() {
    final now = DateTime.now();
    final monday = _getMondayOfWeek(now);
    final days = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });

    return ChartSeries(
      name: 'Weight (kg)',
      dataPoints: days.map((date) {
        // Sample weight data (79-85 kg range)
        final weight = 79 + (date.day % 7) * 0.8 + (date.day % 3) * 0.2;
        return ChartDataPoint(
          value: weight,
          label: _getDayLabel(date),
        );
      }).toList(),
      color: const Color(0xFF00D4AA), // Teal
    );
  }

  /// Get calories chart data
  ChartSeries _getCaloriesChartData() {
    final now = DateTime.now();
    final monday = _getMondayOfWeek(now);
    final days = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });

    return ChartSeries(
      name: 'Calories',
      dataPoints: days.map((date) {
        // Sample calories data (500-2500 kcal range)
        final calories = 500 + (date.day % 7) * 300;
        return ChartDataPoint(
          value: calories.toDouble(),
          label: _getDayLabel(date),
        );
      }).toList(),
      color: const Color(0xFFFF6B35), // Orange
    );
  }

  /// Get sleep chart data
  ChartSeries _getSleepChartData() {
    final now = DateTime.now();
    final monday = _getMondayOfWeek(now);
    final days = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });

    return ChartSeries(
      name: 'Sleep (hrs)',
      dataPoints: days.map((date) {
        // Sample sleep data (2-10 hours range)
        final sleep = 2 + (date.day % 5) * 2;
        return ChartDataPoint(
          value: sleep.toDouble(),
          label: _getDayLabel(date),
        );
      }).toList(),
      color: const Color(0xFFFF006E), // Pink
    );
  }

  String _getDayLabel(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  /// Build Google Fit connection banner
  Widget _buildGoogleFitBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to permissions screen
        context.push(PermissionsScreen.route);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.fitness_center,
                color: AppColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect with Google Fit',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Connect to track your fitness data and health metrics',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
