import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';

/// Service to handle all permission requests for Google Fit API
class PermissionService {
  Future<bool> requestAndroidPermissions() async {
    try {
      if (!Platform.isAndroid) return true;

      final bodySensorsStatus = await ph.Permission.sensors.request();
      final activityStatus = await ph.Permission.activityRecognition.request();
      await ph.Permission.location.request();

      final bodySensorsGranted = bodySensorsStatus.isGranted;
      final activityGranted = activityStatus.isGranted;

      return bodySensorsGranted && activityGranted;
    } catch (e) {
      debugPrint('PermissionService: Error requesting Android permissions: $e');
      return false;
    }
  }

  Future<bool> isGoogleFitAvailable() async {
    if (!Platform.isAndroid) return false;
    return true;
  }

  Future<bool> requestGoogleFitPermissions() async {
    try {
      final repository = getIt<GoogleFitRepository>();
      final permissionResult = await repository.requestPermissions();

      return permissionResult.fold(
        (failure) => _requestGoogleFitDirectly(),
        (granted) => granted ? true : _requestGoogleFitDirectly(),
      );
    } catch (e) {
      debugPrint('PermissionService: Error requesting Google Fit permissions: $e');
      return _requestGoogleFitDirectly();
    }
  }

  Future<bool> _requestGoogleFitDirectly() async {
    try {
      final googleSignIn = getIt<GoogleSignIn>();
      final account = await googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      debugPrint('PermissionService: Error in Google Fit request: $e');
      return false;
    }
  }

  Future<bool> tryRegisterWithGoogleFit() async {
    try {
      final googleSignIn = getIt<GoogleSignIn>();
      final account = await googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      return auth.accessToken != null;
    } catch (e) {
      debugPrint('PermissionService: Error registering with Google Fit: $e');
      return false;
    }
  }

  Future<bool> connectToGoogleFit() async {
    try {
      final repository = getIt<GoogleFitRepository>();
      final hasPermissionsResult = await repository.hasPermissions();
      
      return hasPermissionsResult.fold(
        (failure) => false,
        (hasPerms) => hasPerms,
      );
    } catch (e) {
      debugPrint('PermissionService: Error connecting to Google Fit: $e');
      return false;
    }
  }

  Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e) {
      debugPrint('PermissionService: Error opening app settings: $e');
    }
  }
  
  Future<bool> areAllPermissionsGranted() async {
    try {
      if (!Platform.isAndroid) return true;

      final bodySensorsGranted = await ph.Permission.sensors.isGranted;
      final activityGranted = await ph.Permission.activityRecognition.isGranted;

      if (!bodySensorsGranted || !activityGranted) return false;

      final repository = getIt<GoogleFitRepository>();
      final hasPermissionsResult = await repository.hasPermissions();
      
      return hasPermissionsResult.fold(
        (failure) => false,
        (hasPerms) => hasPerms,
      );
    } catch (e) {
      debugPrint('PermissionService: Error checking permissions: $e');
      return false;
    }
  }
}
