import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/bloc/home_state.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:befit_fitness_app/src/auth/presentation/bloc/auth_event.dart';

/// Custom drawer widget for home screen
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
                  icon: Icons.calculate,
                  title: 'Health Calculator',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Health Calculator
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.restaurant,
                  title: 'Diet Planner',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Diet Planner
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Workout Section',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Workout Section
                  },
                ),
              ],
            ),
          ),
          // Logout button at bottom
          const Divider(height: 1),
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
        top: 60.h,
        bottom: 20.h,
        left: 20.w,
        right: 20.w,
      ),
      color: AppColors.primary,
      child: Column(
        children: [
          // Profile icon
          CircleAvatar(
            radius: 50.r,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null
                ? Icon(
                    Icons.person,
                    size: 50.r,
                    color: AppColors.primary,
                  )
                : null,
          ),
          SizedBox(height: 15.h),
          // User name
          Text(
            userName,
            style: GoogleFonts.ubuntu(
              color: Colors.black,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
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
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: GoogleFonts.ubuntu(
          color: isLogout ? Colors.red : AppColors.textPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
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
}

