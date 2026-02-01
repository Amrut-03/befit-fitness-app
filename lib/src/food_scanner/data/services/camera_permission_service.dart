import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Service to handle camera permissions and hardware availability
class CameraPermissionService {
  /// Check camera permission status
  Future<CameraPermissionStatus> checkCameraPermission() async {
    try {
      // Check permission status
      final status = await ph.Permission.camera.status;
      
      if (status.isGranted) {
        return CameraPermissionStatus.granted;
      } else if (status.isDenied) {
        return CameraPermissionStatus.denied;
      } else if (status.isPermanentlyDenied) {
        return CameraPermissionStatus.permanentlyDenied;
      } else if (status.isRestricted) {
        return CameraPermissionStatus.restricted;
      } else {
        return CameraPermissionStatus.denied;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CameraPermissionService: Error checking permission: $e');
      return CameraPermissionStatus.unknown;
    }
  }

  /// Request camera permission
  Future<CameraPermissionStatus> requestCameraPermission() async {
    try {
      final status = await ph.Permission.camera.request();
      
      if (status.isGranted) {
        return CameraPermissionStatus.granted;
      } else if (status.isPermanentlyDenied) {
        return CameraPermissionStatus.permanentlyDenied;
      } else {
        return CameraPermissionStatus.denied;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CameraPermissionService: Error requesting permission: $e');
      return CameraPermissionStatus.unknown;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }

  /// Check if camera is available (hardware check)
  /// Note: This will be detected when trying to start the camera
  /// Hardware unavailability will be caught as an error when starting the controller
  Future<bool> isCameraAvailable() async {
    // Camera availability is checked when starting the controller
    // If camera is unavailable, it will throw an error
    return true; // Assume available, errors will be caught when starting
  }
}

/// Enum for camera permission status
enum CameraPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  hardwareUnavailable,
  unknown,
}

