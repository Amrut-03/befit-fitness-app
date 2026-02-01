import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/src/auth/presentation/screens/login_page.dart';

/// Splash screen: black background, full app icon (no circle), scale + fade animation.
/// Navigates to login after a short delay; router redirect will send to home/onboarding if logged in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String route = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 800);
  static const Duration _displayDuration = Duration(milliseconds: 2200);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    Future.delayed(_displayDuration, _navigateAway);
  }

  void _navigateAway() {
    if (!mounted) return;
    context.go(LoginPage.route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.contain,
              width: 160,
              height: 160,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.fitness_center,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
