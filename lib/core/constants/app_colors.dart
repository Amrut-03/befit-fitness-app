import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF01FBE2);
  static const Color primaryDark = Color(0xFF08EBE2);
  static const Color primaryLight = Color(0xFF01FBE2);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF2C3E50);
  static const Color secondaryDark = Color(0xFF1A252F);
  static const Color secondaryLight = Color(0xFF34495E);
  
  // Background Colors
  static const Color background = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textOnPrimary = Colors.white;
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Chart Colors
  static const Color chart1 = Color(0xFF2196F3);
  static const Color chart2 = Color(0xFF4CAF50);
  static const Color chart3 = Color(0xFFFF9800);
  static const Color chart4 = Color(0xFF9C27B0);
  
  // Workout Level Colors
  static const Color beginner = Color(0xFF4CAF50);
  static const Color intermediate = Color(0xFFFF9800);
  static const Color advanced = Color(0xFFF44336);
  
  // Health Status Colors
  static const Color excellent = Color(0xFF4CAF50);
  static const Color good = Color(0xFF8BC34A);
  static const Color average = Color(0xFFFF9800);
  static const Color poor = Color(0xFFF44336);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
