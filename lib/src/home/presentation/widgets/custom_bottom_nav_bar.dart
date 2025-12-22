import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onCenterButtonTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterButtonTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation1; // Location button
  late Animation<Offset> _slideAnimation2; // Briefcase button
  late Animation<Offset> _slideAnimation3; // Question mark button

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Rotate from 0 to -90 degrees (counterclockwise) when expanding
    // -90 degrees = -0.25 turns (quarter rotation)
    // Rotates from plus (+) to upward position, then back when closing
    _rotationAnimation = Tween<double>(begin: 0.0, end: -0.25).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Slide animations - buttons start from bottom (center button position) and slide upward
    // Location button (top-center) - slides from bottom to top
    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start from bottom (below center button)
      end: Offset.zero, // Final position
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Briefcase button (top-left) - slides from bottom-left to final position
    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start from bottom
      end: Offset.zero, // Final position
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Question mark button (top-right) - slides from bottom-right to final position
    _slideAnimation3 = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start from bottom
      end: Offset.zero, // Final position
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onFloatingButtonTap(int index) {
    _toggleExpansion();
    // Handle floating button tap
    // You can add navigation or actions here based on index
    // 0: location, 1: briefcase, 2: question mark
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    
    return SizedBox(
      height: 70.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
        // Main navigation bar with notch
        ClipPath(
          clipper: _BottomNavBarClipper(),
          child: Container(
            height: 70.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),
                topRight: Radius.circular(32.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home button
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          color: widget.currentIndex == 0
                              ? AppColors.primary
                              : Colors.grey[600],
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Home',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: widget.currentIndex == 0
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Center space for FAB (notch area)
                SizedBox(width: 60.w),
                // More button
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.more_horiz,
                          color: widget.currentIndex == 2
                              ? AppColors.primary
                              : Colors.grey[600],
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'More',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: widget.currentIndex == 2
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Center FAB
        Positioned(
          bottom: 35.h,
          left: centerX - 30.w,
          child: GestureDetector(
            onTap: () {
              _toggleExpansion();
              widget.onCenterButtonTap?.call();
            },
            child: RotationTransition(
              turns: _rotationAnimation,
              child: Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.add,
                    key: ValueKey<bool>(_isExpanded),
                    color: Colors.white,
                    size: 30.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Floating action buttons (expanded menu) - arranged in an arc
        // Always render them so reverse animation works smoothly
        // Top-center button (Location) - highest point
        Positioned(
          bottom: 140.h,
          left: centerX - 25.w,
          child: IgnorePointer(
            ignoring: !_isExpanded && _animationController.value == 0,
            child: SlideTransition(
              position: _slideAnimation1,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () => _onFloatingButtonTap(0),
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Top-left button (Briefcase) - left arc
        Positioned(
          bottom: 100.h,
          left: centerX - 90.w,
          child: IgnorePointer(
            ignoring: !_isExpanded && _animationController.value == 0,
            child: SlideTransition(
              position: _slideAnimation2,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () => _onFloatingButtonTap(1),
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.work_outline,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Top-right button (Question mark) - right arc
        Positioned(
          bottom: 100.h,
          left: centerX + 40.w,
          child: IgnorePointer(
            ignoring: !_isExpanded && _animationController.value == 0,
            child: SlideTransition(
              position: _slideAnimation3,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () => _onFloatingButtonTap(2),
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

// Custom clipper to create the notch in the navigation bar
class _BottomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final notchRadius = 30.0;
    final centerX = size.width / 2;

    // Start from top-left corner
    path.moveTo(0, 32);
    // Line to start of left curve (rounded corner)
    path.quadraticBezierTo(0, 0, 32, 0);
    // Line to start of notch
    path.lineTo(centerX - notchRadius - 10, 0);
    // Create semi-circular notch (upward curve)
    path.arcToPoint(
      Offset(centerX + notchRadius + 10, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
      largeArc: false,
    );
    // Line to top-right corner
    path.lineTo(size.width - 32, 0);
    // Rounded top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, 32);
    // Line to bottom-right
    path.lineTo(size.width, size.height);
    // Line to bottom-left
    path.lineTo(0, size.height);
    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

