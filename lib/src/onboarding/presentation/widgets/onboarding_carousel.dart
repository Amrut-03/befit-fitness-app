import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/text_rich.dart';
import 'package:befit_fitness_app/src/onboarding/domain/models/onboarding_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

/// Carousel widget that displays all onboarding screens with auto-sliding
class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  Timer? _autoSlideTimer;
  final ValueNotifier<bool> _isUserInteractingNotifier =
      ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _currentPageNotifier.dispose();
    _isUserInteractingNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients &&
          !_isUserInteractingNotifier.value &&
          mounted) {
        final nextPage = (_currentPageNotifier.value + 1) %
            OnboardingContentRepository.totalPages;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _onPageChanged(int index) {
    _currentPageNotifier.value = index;
  }

  void _onPageScrollStart() {
    _isUserInteractingNotifier.value = true;
    // Resume auto-slide after 6 seconds of no interaction
    _stopAutoSlide();
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _isUserInteractingNotifier.value = false;
        _startAutoSlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingContentRepository.getPages(context);

    return Column(
      children: [
        // PageView takes available space
        Expanded(
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (notification) {
              _onPageScrollStart();
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final content = pages[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 300.h,
                        width: 300.w,
                        child: LottieBuilder.asset(
                          content.lottieAssetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: CustomTextRich(
                          text1: '"  ',
                          textColor1: AppColors.primary,
                          fontWeight1: FontWeight.bold,
                          fontSize1: 18.sp,
                          text2: content.getDescription(context),
                          textColor2: AppColors.textPrimary,
                          fontWeight2: FontWeight.bold,
                          fontSize2: 18.sp,
                          text3: '  "',
                          textColor3: AppColors.primary,
                          fontWeight3: FontWeight.bold,
                          fontSize3: 18.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // Page indicators
        ValueListenableBuilder<int>(
          valueListenable: _currentPageNotifier,
          builder: (_, currentPage, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => _buildPageIndicator(index == currentPage),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      height: 8.h,
      width: isActive ? 24.w : 8.w,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : AppColors.textPrimary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}
