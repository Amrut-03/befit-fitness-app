import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class for creating custom marker icons
class CustomMarkerIcon {
  /// Create a custom marker with animated walking man or profile image
  static Future<BitmapDescriptor> createCustomMarker({
    String? profileImageUrl,
    Color? activityColor,
    bool useProfileImage = true,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 120.0; // Size of the marker

    // Draw outer circle with gradient effect
    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = activityColor ?? Colors.blue;

    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(0.3);

    // Draw shadow
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 2),
      size / 2 - 5,
      shadowPaint,
    );

    // Draw outer circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 5,
      outerPaint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 4;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 5,
      borderPaint,
    );

    // Draw inner content
    if (useProfileImage && profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // Draw profile image
      await _drawProfileImage(canvas, size, profileImageUrl);
    } else {
      // Draw animated walking man icon
      _drawWalkingMan(canvas, size, activityColor ?? Colors.white);
    }

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Draw profile image in the marker
  static Future<void> _drawProfileImage(
    Canvas canvas,
    double size,
    String imageUrl,
  ) async {
    try {
      // Load image using NetworkImage
      final imageProvider = NetworkImage(imageUrl);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      
      final completer = Completer<ui.Image>();
      late ImageStreamListener listener;
      
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          completer.complete(info.image);
          imageStream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          completer.completeError(exception);
          imageStream.removeListener(listener);
        },
      );
      
      imageStream.addListener(listener);
      final image = await completer.future;
      
      // Calculate size for the inner circle (profile image)
      final innerSize = size * 0.7;
      final innerRadius = innerSize / 2;
      
      // Create a path for clipping to circle
      final clipPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(size / 2, size / 2),
            radius: innerRadius,
          ),
        );
      
      canvas.save();
      canvas.clipPath(clipPath);
      
      // Draw the image
      final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dstRect = Rect.fromCircle(
        center: Offset(size / 2, size / 2),
        radius: innerRadius,
      );
      
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      canvas.restore();
      
      // Dispose the image
      image.dispose();
    } catch (e) {
      // If image loading fails, fall back to walking man
      _drawWalkingMan(canvas, size, Colors.white);
    }
  }

  /// Draw walking man icon with better styling
  static void _drawWalkingMan(Canvas canvas, double size, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size / 2;
    final centerY = size / 2;
    final scale = size / 120;

    // Head (larger and more visible)
    canvas.drawCircle(
      Offset(centerX, centerY - 28 * scale),
      10 * scale,
      paint,
    );

    // Body (torso) - thicker
    canvas.drawLine(
      Offset(centerX, centerY - 18 * scale),
      Offset(centerX, centerY + 8 * scale),
      paint..strokeWidth = 5 * scale,
    );

    // Left arm (upward and forward - walking motion)
    canvas.drawLine(
      Offset(centerX, centerY - 8 * scale),
      Offset(centerX - 14 * scale, centerY - 22 * scale),
      paint..strokeWidth = 4 * scale,
    );

    // Right arm (downward and back - walking motion)
    canvas.drawLine(
      Offset(centerX, centerY - 5 * scale),
      Offset(centerX + 12 * scale, centerY + 5 * scale),
      paint..strokeWidth = 4 * scale,
    );

    // Left leg (forward - walking motion)
    canvas.drawLine(
      Offset(centerX, centerY + 8 * scale),
      Offset(centerX - 12 * scale, centerY + 25 * scale),
      paint..strokeWidth = 5 * scale,
    );

    // Right leg (backward - walking motion)
    canvas.drawLine(
      Offset(centerX, centerY + 8 * scale),
      Offset(centerX + 10 * scale, centerY + 25 * scale),
      paint..strokeWidth = 5 * scale,
    );
  }

  /// Get user profile image URL from Firebase Auth
  static String? getUserProfileImageUrl() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.photoURL;
  }
}

