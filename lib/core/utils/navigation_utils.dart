import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

/// Navigation utility functions for handling screen transitions
class NavigationUtils {
  /// Navigate to a new screen
  static void push(
    BuildContext context,
    Widget widget, {
    PageTransitionType transitionType = PageTransitionType.rightToLeftWithFade,
    int durationMs = 200,
  }) {
    Navigator.push(
      context,
      PageTransition(
        child: widget,
        type: transitionType,
        duration: Duration(milliseconds: durationMs),
      ),
    );
  }

  /// Navigate to a new screen and replace the current one
  static void pushReplacement(
    BuildContext context,
    Widget widget, {
    PageTransitionType transitionType = PageTransitionType.rightToLeftWithFade,
    int durationMs = 200,
  }) {
    Navigator.pushReplacement(
      context,
      PageTransition(
        child: widget,
        type: transitionType,
        duration: Duration(milliseconds: durationMs),
      ),
    );
  }

  /// Navigate to a new screen and remove all previous routes
  static void pushAndRemoveUntil(
    BuildContext context,
    Widget widget, {
    PageTransitionType transitionType = PageTransitionType.rightToLeftWithFade,
    int durationMs = 200,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      PageTransition(
        child: widget,
        type: transitionType,
        duration: Duration(milliseconds: durationMs),
      ),
      (Route<dynamic> route) => false,
    );
  }

  /// Navigate back
  static void pop(BuildContext context) {
    Navigator.pop(context);
  }
}

