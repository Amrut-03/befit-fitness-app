import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';
import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/src/google_fit/domain/repositories/google_fit_repository.dart';
import 'package:health/health.dart';

/// Service to handle all permission requests
class PermissionService {
  /// Request all Android permissions using permission_handler
  Future<bool> requestAndroidPermissions() async {
    try {
      if (!Platform.isAndroid) {
        return true; // iOS handles permissions differently
      }

      debugPrint('PermissionService: Requesting Android permissions...');

      // Request Body Sensors permission
      final bodySensorsStatus = await ph.Permission.sensors.request();
      debugPrint('PermissionService: Body Sensors: $bodySensorsStatus');

      // Request Activity Recognition permission (for steps)
      final activityStatus = await ph.Permission.activityRecognition.request();
      debugPrint('PermissionService: Activity Recognition: $activityStatus');

      // Request Location permission (optional, for distance tracking)
      final locationStatus = await ph.Permission.location.request();
      debugPrint('PermissionService: Location: $locationStatus');

      // Check if critical permissions are granted
      final bodySensorsGranted = bodySensorsStatus.isGranted;
      final activityGranted = activityStatus.isGranted;

      if (!bodySensorsGranted || !activityGranted) {
        debugPrint('PermissionService: Critical permissions not granted');
        return false;
      }

      debugPrint('PermissionService: All Android permissions granted');
      return true;
    } catch (e) {
      debugPrint('PermissionService: Error requesting Android permissions: $e');
      return false;
    }
  }

  /// Check if Health Connect is available/installed
  Future<bool> isHealthConnectAvailable() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }
      
      final health = getIt<Health>();
      // Try to check if Health Connect is available by checking permissions
      // This will fail if Health Connect is not installed
      try {
        const types = [HealthDataType.STEPS];
        final hasPerms = await health.hasPermissions(types);
        // If we can check permissions, Health Connect is likely available
        return true;
      } catch (e) {
        debugPrint('PermissionService: Health Connect may not be available: $e');
        return false;
      }
    } catch (e) {
      debugPrint('PermissionService: Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Request Health Connect permissions
  Future<bool> requestHealthConnectPermissions() async {
    try {
      debugPrint('PermissionService: Requesting Health Connect permissions...');

      // Step 0: Check if Health Connect is available
      final isAvailable = await isHealthConnectAvailable();
      if (!isAvailable) {
        debugPrint('PermissionService: Health Connect may not be installed or available');
        // Continue anyway - the attempt might still work
      }

      // Step 1: Try to register first by attempting data operations
      // This is critical - Health Connect needs to "see" the app before permission requests work
      debugPrint('PermissionService: Step 1 - Attempting to register app with Health Connect...');
      await tryRegisterWithHealthConnect();
      
      // Wait a moment for Health Connect to process the registration
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 2: Try using the repository
      debugPrint('PermissionService: Step 2 - Requesting permissions via repository...');
      final repository = getIt<GoogleFitRepository>();
      final permissionResult = await repository.requestPermissions();

      return permissionResult.fold(
        (failure) {
          debugPrint('PermissionService: Health Connect permission request failed: ${failure.message}');
          
          // Step 3: Try direct Health package method
          debugPrint('PermissionService: Step 3 - Trying direct Health package method...');
          return _requestHealthConnectDirectly();
        },
        (granted) {
          if (granted) {
            debugPrint('PermissionService: Health Connect permissions granted via repository');
            return true;
          } else {
            debugPrint('PermissionService: Health Connect permissions not granted, trying direct method');
            return _requestHealthConnectDirectly();
          }
        },
      );
    } catch (e) {
      debugPrint('PermissionService: Error requesting Health Connect permissions: $e');
      // Even if there's an error, try the direct method as a last resort
      return _requestHealthConnectDirectly();
    }
  }

  /// Request Health Connect permissions directly using Health package
  Future<bool> _requestHealthConnectDirectly() async {
    try {
      final health = getIt<Health>();
      const types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.HEART_RATE,
      ];

      final granted = await health.requestAuthorization(types);
      debugPrint('PermissionService: Health Connect direct request result: $granted');
      return granted;
    } catch (e) {
      debugPrint('PermissionService: Error in direct Health Connect request: $e');
      return false;
    }
  }

  /// Try to register app with Health Connect by attempting to write data
  Future<bool> tryRegisterWithHealthConnect() async {
    try {
      debugPrint('PermissionService: Attempting to register with Health Connect...');
      final health = getIt<Health>();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(hours: 1));

      // Method 1: Try to request authorization first - this is the primary way to register
      try {
        const types = [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ];
        debugPrint('PermissionService: Attempting authorization request to trigger registration...');
        final granted = await health.requestAuthorization(types);
        debugPrint('PermissionService: Authorization request result: $granted');
        if (granted) {
          return true; // Successfully registered and got permissions
        }
      } catch (e) {
        debugPrint('PermissionService: Authorization request failed (may still trigger registration): $e');
      }

      // Method 2: Try to write test data - this might trigger Health Connect to register the app
      try {
        debugPrint('PermissionService: Attempting to write test data to trigger registration...');
        await health.writeHealthData(
          value: 0.0,
          type: HealthDataType.STEPS,
          unit: HealthDataUnit.COUNT,
          startTime: startOfDay,
          endTime: endOfDay,
        );
        debugPrint('PermissionService: Successfully wrote test data');
      } catch (e) {
        debugPrint('PermissionService: Write attempt failed (may still trigger registration): $e');
      }

      // Method 3: Also try to read data - this might also trigger registration
      try {
        debugPrint('PermissionService: Attempting to read data to trigger registration...');
        await health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startOfDay,
          endTime: endOfDay,
        );
        debugPrint('PermissionService: Successfully attempted data read');
      } catch (e) {
        debugPrint('PermissionService: Read attempt failed: $e');
      }

      // Method 4: Try requesting authorization again after data operations
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        const types = [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ];
        final granted = await health.requestAuthorization(types);
        debugPrint('PermissionService: Second authorization request result: $granted');
        return granted;
      } catch (e) {
        debugPrint('PermissionService: Second authorization request failed: $e');
      }

      return true; // Return true even if all methods fail - the attempt may have triggered registration
    } catch (e) {
      debugPrint('PermissionService: Error trying to register with Health Connect: $e');
      return false;
    }
  }

  /// Connect to Health Connect (verify connection)
  Future<bool> connectToHealthConnect() async {
    try {
      debugPrint('PermissionService: Verifying Health Connect connection...');
      final repository = getIt<GoogleFitRepository>();
      
      // Check if we have permissions
      final hasPermissionsResult = await repository.hasPermissions();
      
      return hasPermissionsResult.fold(
        (failure) {
          debugPrint('PermissionService: No Health Connect permissions: ${failure.message}');
          return false;
        },
        (hasPerms) {
          if (hasPerms) {
            debugPrint('PermissionService: Health Connect connected successfully');
            return true;
          } else {
            debugPrint('PermissionService: Health Connect permissions not granted');
            return false;
          }
        },
      );
    } catch (e) {
      debugPrint('PermissionService: Error connecting to Health Connect: $e');
      return false;
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      // Call the top-level function from permission_handler
      await ph.openAppSettings();
      debugPrint('PermissionService: Opened app settings');
    } catch (e) {
      debugPrint('PermissionService: Error opening app settings: $e');
    }
  }
  
  /// Check if all permissions are already granted
  Future<bool> areAllPermissionsGranted() async {
    try {
      if (!Platform.isAndroid) {
        return true;
      }

      // Check Android permissions
      final bodySensorsGranted = await ph.Permission.sensors.isGranted;
      final activityGranted = await ph.Permission.activityRecognition.isGranted;

      if (!bodySensorsGranted || !activityGranted) {
        return false;
      }

      // Check Health Connect permissions
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

  /// Open Health Connect app
  Future<void> openHealthConnect() async {
    try {
      if (Platform.isAndroid) {
        const packageName = 'com.google.android.apps.healthdata';
        
        // Method 1: Try to open Health Connect's app permissions screen directly
        try {
          // Health Connect's app permissions intent
          final intentUri = Uri.parse('android-app://$packageName/healthconnect.permission');
          if (await canLaunchUrl(intentUri)) {
            await launchUrl(intentUri, mode: LaunchMode.externalApplication);
            debugPrint('PermissionService: Opened Health Connect permissions screen');
            return;
          }
        } catch (e) {
          debugPrint('PermissionService: Could not open Health Connect permissions screen: $e');
        }
        
        // Method 2: Try to open Health Connect app directly
        try {
          final uri = Uri.parse('android-app://$packageName');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint('PermissionService: Opened Health Connect app');
            return;
          }
        } catch (e) {
          debugPrint('PermissionService: Could not open Health Connect: $e');
        }
        
        // Method 3: Try Play Store if not installed
        try {
          final playStoreUri = Uri.parse('market://details?id=$packageName');
          if (await canLaunchUrl(playStoreUri)) {
            await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
            debugPrint('PermissionService: Opened Health Connect in Play Store');
            return;
          }
        } catch (e) {
          debugPrint('PermissionService: Could not open Play Store: $e');
        }
      }
    } catch (e) {
      debugPrint('PermissionService: Error opening Health Connect: $e');
    }
  }
}

