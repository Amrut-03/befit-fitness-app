import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hidden_drawer_menu/controllers/simple_hidden_drawer_controller.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/home/data/services/delete_account_service.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';

/// Interactive tile with scale-on-press and haptic feedback
class _InteractiveDrawerTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isLogout;

  const _InteractiveDrawerTile({
    required this.child,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  State<_InteractiveDrawerTile> createState() => _InteractiveDrawerTileState();
}

class _InteractiveDrawerTileState extends State<_InteractiveDrawerTile> {
  final ValueNotifier<bool> _pressedNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _pressedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!mounted) return;
        _pressedNotifier.value = true;
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _pressedNotifier.value = false,
      onTapCancel: () => _pressedNotifier.value = false,
      onTap: widget.onTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: _pressedNotifier,
        builder: (_, pressed, __) => AnimatedScale(
          scale: pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hidden drawer menu panel for SimpleHiddenDrawer – interactive slide-in menu
class HiddenDrawerMenuContent extends StatefulWidget {
  const HiddenDrawerMenuContent({super.key});

  @override
  State<HiddenDrawerMenuContent> createState() => _HiddenDrawerMenuContentState();
}

class _HiddenDrawerMenuContentState extends State<HiddenDrawerMenuContent>
    with SingleTickerProviderStateMixin {
  SimpleHiddenDrawerController? _controller;
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = SimpleHiddenDrawerController.of(context);
  }

  void _closeAnd(VoidCallback action) {
    _controller?.close();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'User';
    final photoUrl = user?.photoURL;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            right: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _entranceAnimation,
            builder: (context, _) {
              return Column(
                children: [
                  _buildAnimatedSection(
                    child: _buildProfileSection(userName, photoUrl),
                    interval: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
                    withScale: true,
                  ),
                  _buildAnimatedSection(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 4.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Menu',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    interval: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        _buildAnimatedSection(
                          child: _InteractiveDrawerTile(
                            onTap: () => _closeAnd(() => context.push('/profile')),
                            child: _buildDrawerItemContent(
                              context,
                              icon: Icons.person_outline_rounded,
                              title: 'Profile',
                              isLogout: false,
                            ),
                          ),
                          interval: const Interval(0.2, 0.45, curve: Curves.easeOutCubic),
                        ),
                        SizedBox(height: 10.h),
                        _buildAnimatedSection(
                          child: _InteractiveDrawerTile(
                            onTap: () => _closeAnd(() => context.push('/my-food-items')),
                            child: _buildDrawerItemContent(
                              context,
                              icon: Icons.restaurant_menu_outlined,
                              title: 'Food Items',
                              isLogout: false,
                            ),
                          ),
                          interval: const Interval(0.2, 0.45, curve: Curves.easeOutCubic),
                        ),
                        SizedBox(height: 10.h),
                        _buildAnimatedSection(
                          child: _InteractiveDrawerTile(
                            onTap: () => _closeAnd(() => context.push('/daily-macros')),
                            child: _buildDrawerItemContent(
                              context,
                              icon: Icons.pie_chart_outline_rounded,
                              title: 'Daily Macros',
                              isLogout: false,
                            ),
                          ),
                          interval: const Interval(0.25, 0.5, curve: Curves.easeOutCubic),
                        ),
                        SizedBox(height: 10.h),
                        _buildAnimatedSection(
                          child: _InteractiveDrawerTile(
                            onTap: () => _closeAnd(() => context.push('/diet-planning')),
                            child: _buildDrawerItemContent(
                              context,
                              icon: Icons.restaurant_outlined,
                              title: 'Diet Planner',
                              isLogout: false,
                            ),
                          ),
                          interval: const Interval(0.3, 0.55, curve: Curves.easeOutCubic),
                        ),
                        SizedBox(height: 10.h),
                        _buildAnimatedSection(
                          child: _InteractiveDrawerTile(
                            onTap: () => _closeAnd(() => context.push('/workout-list')),
                            child: _buildDrawerItemContent(
                              context,
                              icon: Icons.fitness_center,
                              title: 'Workout Section',
                              isLogout: false,
                            ),
                          ),
                          interval: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  _buildAnimatedSection(
                    child: _InteractiveDrawerTile(
                      onTap: () => _closeAnd(() => _showDeleteAccountConfirmationDialog(context)),
                      isLogout: false,
                      child: _buildDrawerItemContent(
                        context,
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete account',
                        isLogout: false,
                        isDeleteAccount: true,
                      ),
                    ),
                    interval: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
                  ),
                  SizedBox(height: 10.h),
                  _buildAnimatedSection(
                    child: _InteractiveDrawerTile(
                      onTap: () => _closeAnd(() => _showSignOutConfirmationDialog(context)),
                      isLogout: true,
                      child: _buildDrawerItemContent(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isLogout: true,
                      ),
                    ),
                    interval: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
                  ),
                  SizedBox(height: 24.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required Widget child,
    Interval interval = const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
    bool withScale = false,
  }) {
    final anim = CurvedAnimation(
      parent: _entranceAnimation,
      curve: interval,
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final scale = withScale ? 0.92 + (0.08 * anim.value) : 1.0;
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(-30 * (1 - anim.value), 0),
            child: Transform.scale(
              alignment: Alignment.centerLeft,
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(String userName, String? photoUrl) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: CircleAvatar(
              radius: 36.r,
              backgroundColor: Colors.black,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      size: 36.sp,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            userName,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap outside to close',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11.sp,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItemContent(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isLogout = false,
    bool isDeleteAccount = false,
  }) {
    final iconColor = isLogout
        ? AppColors.error
        : (isDeleteAccount ? Colors.orange : AppColors.primary);
    final textColor = isLogout
        ? AppColors.error
        : (isDeleteAccount ? Colors.orange : Colors.white);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isLogout
              ? AppColors.error.withOpacity(0.3)
              : (isDeleteAccount
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: iconColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.ubuntu(
                color: textColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: textColor.withOpacity(0.5),
            size: 14.sp,
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmationDialog(BuildContext context) {
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
                onPressed: () => Navigator.of(dialogContext).pop(),
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  authBloc.add(const SignOutEvent());
                },
                child: Text(
                  'Log out',
                  style: GoogleFonts.ubuntu(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: authBloc,
          child: AlertDialog(
            title: Text(
              'Delete account',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'All data collected by this app will be permanently deleted, including your profile, diet plans, food items, daily goals, and macros. You will be signed out. This cannot be undone.',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ubuntu(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final scaffoldContext = context;
                  try {
                    await getIt<DeleteAccountService>().deleteAllUserData();
                    if (scaffoldContext.mounted) {
                      authBloc.add(const SignOutEvent());
                      scaffoldContext.go(LoginPage.route);
                    }
                  } catch (e) {
                    if (scaffoldContext.mounted) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete data: $e',
                            style: GoogleFonts.ubuntu(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Delete my data',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom drawer widget for home screen (legacy – used when not using HiddenDrawerMenu)
class HomeDrawer extends StatelessWidget {
  final HomeLoaded state;

  const HomeDrawer({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = state.userProfile.firstName ??
        user?.displayName ??
        user?.email?.split('@')[0] ??
        'User';
    final photoUrl = user?.photoURL;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Profile section at top
          _buildProfileSection(userName, photoUrl),
          // Features section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: 20.h),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Food Items',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/my-food-items');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Daily Macros',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/daily-macros');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.restaurant,
                  title: 'Diet Planner',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/diet-planning');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Workout Section',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/workout-list');
                  },
                ),
              ],
            ),
          ),
          // Delete account and Logout at bottom
          const Divider(height: 1),
          _buildDrawerItem(
            context,
            icon: Icons.delete_forever_rounded,
            title: 'Delete account',
            onTap: () {
              Navigator.pop(context);
              _showDeleteAccountConfirmationDialog(context);
            },
            isDeleteAccount: true,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pop(context);
              _showSignOutConfirmationDialog(context);
            },
            isLogout: true,
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String userName, String? photoUrl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 48.h,
        bottom: 20.h,
        left: 20.w,
        right: 20.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: CircleAvatar(
              radius: 36.r,
              backgroundColor: Colors.black,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(Icons.person_rounded, size: 36.sp, color: AppColors.primary)
                  : null,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            userName,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    bool isDeleteAccount = false,
  }) {
    final iconColor = isLogout
        ? AppColors.error
        : (isDeleteAccount ? Colors.orange : AppColors.primary);
    final textColor = isLogout
        ? AppColors.error
        : (isDeleteAccount ? Colors.orange : Colors.white);
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24.sp),
      title: Text(
        title,
        style: GoogleFonts.ubuntu(
          color: textColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
      onTap: onTap,
    );
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

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: authBloc,
          child: AlertDialog(
            title: Text(
              'Delete account',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'All data collected by this app will be permanently deleted, including your profile, diet plans, food items, daily goals, and macros. You will be signed out. This cannot be undone.',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ubuntu(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final scaffoldContext = context;
                  try {
                    await getIt<DeleteAccountService>().deleteAllUserData();
                    if (scaffoldContext.mounted) {
                      authBloc.add(const SignOutEvent());
                      scaffoldContext.go(LoginPage.route);
                    }
                  } catch (e) {
                    if (scaffoldContext.mounted) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete data: $e',
                            style: GoogleFonts.ubuntu(),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Delete my data',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

