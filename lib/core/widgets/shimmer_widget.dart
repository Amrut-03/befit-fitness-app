import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Wraps [child] with an animated shimmer gradient overlay.
/// Use for skeleton placeholders (e.g. Container with grey rounded rect).
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final slide = _animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + slide * 2, 0),
              end: Alignment(1.0 + slide * 2, 0),
              colors: const [
                Color(0xFF2A2A2A),
                Color(0xFF3D3D3D),
                Color(0xFF4A4A4A),
                Color(0xFF3D3D3D),
                Color(0xFF2A2A2A),
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A simple box placeholder for shimmer (rounded rect).
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
      ),
    );
  }
}

/// Full-page shimmer for profile screen (avatar + lines).
class ShimmerProfilePage extends StatelessWidget {
  const ShimmerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          ShimmerLoading(
            child: Container(
              width: 96.r,
              height: 96.r,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          ShimmerBox(width: 180.w, height: 20.h, borderRadius: 6),
          SizedBox(height: 32.h),
          ShimmerBox(width: double.infinity, height: 56.h),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 56.h),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 52.h)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerBox(height: 52.h)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerBox(height: 52.h)),
            ],
          ),
          SizedBox(height: 24.h),
          ShimmerBox(width: 120.w, height: 18.h),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(6, (_) => ShimmerBox(width: 80.w, height: 36.h)),
          ),
          SizedBox(height: 24.h),
          ShimmerBox(width: 100.w, height: 18.h),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(5, (_) => ShimmerBox(width: 90.w, height: 36.h)),
          ),
          SizedBox(height: 32.h),
          ShimmerBox(width: double.infinity, height: 52.h, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Shimmer for list of cards (e.g. food items, diet plans).
class ShimmerListCards extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final double spacing;

  const ShimmerListCards({
    super.key,
    this.itemCount = 6,
    this.cardHeight = 100,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: spacing.h),
        child: ShimmerLoading(
          child: Container(
            height: cardHeight.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for workout exercise list (image + text lines).
class ShimmerWorkoutList extends StatelessWidget {
  final int itemCount;

  const ShimmerWorkoutList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: itemCount,
      itemBuilder: (_, __) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ShimmerLoading(
            child: Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100.w,
                    margin: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 16.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 12.h,
                            width: 120.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(4.r),
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
        );
      },
    );
  }
}

/// Shimmer for daily macros / stats (cards in column).
class ShimmerMacrosPage extends StatelessWidget {
  const ShimmerMacrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 200.w, height: 28.h, borderRadius: 6),
          SizedBox(height: 24.h),
          ShimmerBox(width: double.infinity, height: 120.h, borderRadius: 16),
          SizedBox(height: 24.h),
          ShimmerBox(width: 160.w, height: 24.h, borderRadius: 6),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 100.h, borderRadius: 12),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 100.h, borderRadius: 12),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 100.h, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Shimmer for diet planning (grid or list of plan cards).
class ShimmerDietPlanning extends StatelessWidget {
  const ShimmerDietPlanning({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: ShimmerLoading(
          child: Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for plan your diet screen (name + macro + list).
class ShimmerPlanYourDiet extends StatelessWidget {
  const ShimmerPlanYourDiet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20.w),
          child: ShimmerBox(width: double.infinity, height: 48.h, borderRadius: 12),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ShimmerBox(width: double.infinity, height: 100.h, borderRadius: 12),
        ),
        SizedBox(height: 24.h),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ShimmerLoading(
                child: Container(
                  height: 72.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer for goal editing page (form fields).
class ShimmerGoalEditing extends StatelessWidget {
  const ShimmerGoalEditing({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 56.h),
          SizedBox(height: 20.h),
          ShimmerBox(width: double.infinity, height: 72.h),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 72.h),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 72.h),
          SizedBox(height: 20.h),
          ShimmerBox(width: double.infinity, height: 80.h),
          SizedBox(height: 30.h),
          ShimmerBox(width: double.infinity, height: 52.h, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Shimmer for home page content (mixed sections).
class ShimmerHomeContent extends StatelessWidget {
  const ShimmerHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          ShimmerBox(width: 140.w, height: 24.h),
          SizedBox(height: 20.h),
          ShimmerBox(width: double.infinity, height: 100.h, borderRadius: 16),
          SizedBox(height: 24.h),
          ShimmerBox(width: 120.w, height: 20.h),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 80.h)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerBox(height: 80.h)),
              SizedBox(width: 12.w),
              Expanded(child: ShimmerBox(height: 80.h)),
            ],
          ),
          SizedBox(height: 24.h),
          ShimmerBox(width: 180.w, height: 22.h),
          SizedBox(height: 12.h),
          ShimmerBox(width: double.infinity, height: 160.h, borderRadius: 12),
          SizedBox(height: 24.h),
          ShimmerBox(width: 160.w, height: 20.h),
          SizedBox(height: 12.h),
          ShimmerBox(width: double.infinity, height: 120.h, borderRadius: 12),
          SizedBox(height: 16.h),
          ShimmerBox(width: double.infinity, height: 120.h, borderRadius: 12),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}
