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
import 'package:befit_fitness_app/src/home/presentation/bloc/home_bloc.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_event.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/animated_text_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/calculator_readings_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/calculator_values_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/home_card_widget.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/search_widget.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';

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

  String get _userEmail {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? '';
  }

  @override
  void initState() {
    super.initState();
    // Fetch home data when screen loads
    context.read<HomeBloc>().add(FetchHomeDataEvent(_userEmail));
    _startAutoScroll();
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


  void _showSignOutConfirmationDialog(BuildContext context) {
    // Get AuthBloc from the outer context before showing dialog
    final authBloc = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: authBloc,
          child: AlertDialog(
            title: Text(
              'Confirm Logout',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ubuntu(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Log out',
                  style: GoogleFonts.ubuntu(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  authBloc.add(const SignOutEvent());
                },
              ),
            ],
          ),
        );
      },
    );
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
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
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
                    top: 30,
                    child: InkWell(
                      onTap: () => _showSignOutConfirmationDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          children: [
                            Text(
                              'Log-out',
                              style: GoogleFonts.ubuntu(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            const Icon(Icons.logout_outlined),
                          ],
                        ),
                      ),
                    ),
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
                  bmi: state.healthMetrics.bmi ?? 0.0,
                  bmr: state.healthMetrics.bmr ?? 0,
                  hrc: state.healthMetrics.hrc ?? 0,
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

