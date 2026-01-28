import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/food_product_details_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/data/datasources/food_api_data_source.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/camera_permission_service.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/widgets/camera_permission_widget.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/widgets/user_education_bottom_sheet.dart';

/// Screen for scanning barcodes of food products
class BarcodeScannerScreen extends StatefulWidget {
  static const String route = '/barcode-scanner';

  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  
  final FoodApiDataSource _apiDataSource = FoodApiDataSource();
  final CameraPermissionService _permissionService = CameraPermissionService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.unknown;
  bool _hasCheckedPermission = false;
  int _scanAttempts = 0;
  String? _currentScanTip;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _updateScanTip();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await _permissionService.checkCameraPermission();
    if (mounted) {
    setState(() {
      _permissionStatus = status;
      _hasCheckedPermission = true;
    });

      // Start camera when permission is granted
    if (status == CameraPermissionStatus.granted) {
        _startCameraSafely();
      }
    }
  }

  Future<void> _startCameraSafely() async {
    try {
      // Try to start the camera
      await _controller.start();
      debugPrint('BarcodeScannerScreen: Camera started successfully');
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      // If already started, that's fine - camera is working
      if (errorString.contains('already started') || 
          errorString.contains('called start() while already started')) {
        debugPrint('BarcodeScannerScreen: Camera already started - this is fine');
      } else {
      debugPrint('BarcodeScannerScreen: Error starting camera: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await _permissionService.requestCameraPermission();
    if (mounted) {
    setState(() {
      _permissionStatus = status;
    });

      // Start camera when permission is granted
    if (status == CameraPermissionStatus.granted) {
        _startCameraSafely();
      }
    }

    if (status == CameraPermissionStatus.permanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _openSettings() async {
    await _permissionService.openAppSettings();
  }

  /// Extract barcode number from raw value (handles URLs and other formats)
  String? _extractBarcodeNumber(String? rawValue, {bool isFromCamera = false}) {
    if (rawValue == null || rawValue.isEmpty) return null;
    
    // Remove whitespace
    String cleaned = rawValue.trim();
    
    // For camera scans, barcode is usually already clean (just digits)
    // So we can return it directly if it's already a valid barcode
    if (isFromCamera) {
      // Check if it's already just digits with valid length
      if (RegExp(r'^\d{8,13}$').hasMatch(cleaned)) {
        return cleaned;
      }
      // If it has some formatting but is mostly digits, extract digits
      final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length >= 8 && digitsOnly.length <= 13) {
        return digitsOnly;
      }
      // For camera, be more lenient - return digits even if length is slightly off
      if (digitsOnly.isNotEmpty && digitsOnly.length >= 6) {
        return digitsOnly;
      }
    }
    
    // For gallery images, handle URLs and other formats
    // If it's a URL, try to extract the barcode from the path
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      // Extract numbers from URL path (e.g., https://dl.ulcp.io/01/8901030743047 -> 8901030743047)
      final uriMatch = RegExp(r'/(\d+)/?$').firstMatch(cleaned);
      if (uriMatch != null) {
        cleaned = uriMatch.group(1) ?? cleaned;
      } else {
        // Try to find any sequence of 8+ digits in the URL
        final digitMatch = RegExp(r'\d{8,}').firstMatch(cleaned);
        if (digitMatch != null) {
          cleaned = digitMatch.group(0) ?? cleaned;
        }
      }
    }
    
    // Extract only digits (EAN/UPC barcodes are typically 8-13 digits)
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    
    // Validate barcode length (EAN-8: 8 digits, EAN-13: 13 digits, UPC-A: 12 digits)
    if (digitsOnly.length >= 8 && digitsOnly.length <= 13) {
      return digitsOnly;
    }
    
    // If we have digits but wrong length, still return them (might be valid)
    if (digitsOnly.isNotEmpty) {
      return digitsOnly;
    }
    
    return null;
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      // Use mobile_scanner to analyze the image
      final file = File(image.path);
      final capture = await _controller.analyzeImage(file.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        final barcodeNumber = _extractBarcodeNumber(barcode.rawValue);
        
        if (barcodeNumber != null && barcodeNumber.isNotEmpty) {
          debugPrint('BarcodeScannerScreen: Extracted barcode from image: $barcodeNumber (original: ${barcode.rawValue})');
          await _processBarcode(barcodeNumber);
        } else {
          debugPrint('BarcodeScannerScreen: Could not extract valid barcode from: ${barcode.rawValue}');
          _showBarcodeNotFoundDialog();
        }
      } else {
        _showBarcodeNotFoundDialog();
      }
    } catch (e) {
      debugPrint('BarcodeScannerScreen: Error analyzing image: $e');
      if (mounted) {
        _showErrorDialog('Failed to scan image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    // Extract clean barcode number (from camera, so use isFromCamera flag)
    final barcodeNumber = _extractBarcodeNumber(barcode.rawValue, isFromCamera: true);
    if (barcodeNumber == null || barcodeNumber.isEmpty) {
      debugPrint('BarcodeScannerScreen: Could not extract barcode from camera scan: ${barcode.rawValue}');
      return;
    }

    debugPrint('BarcodeScannerScreen: Camera detected barcode: $barcodeNumber (original: ${barcode.rawValue})');

    setState(() {
      _scanAttempts++;
      if (_scanAttempts > 3) {
        _updateScanTip();
        _scanAttempts = 0;
      }
    });

    await _processBarcode(barcodeNumber);
  }

  Future<void> _processBarcode(String barcodeValue) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isLoading = true;
    });

    try {
      // Don't stop camera - let MobileScanner handle it
      // Just mark as processing to prevent duplicate scans
      
      final product = await _apiDataSource.getProductByBarcode(barcodeValue);
      
      if (!mounted) return;

      if (product != null) {
        // Navigate to product details
        await context.push(
          FoodProductDetailsScreen.route,
          extra: product,
        );
        // Camera continues running - no need to restart
      } else {
        // Product not found
        _showProductNotFoundDialog(barcodeValue);
        // Camera continues running - no need to restart
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
      // Camera continues running - no need to restart
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
      }
    }
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    _controller.toggleTorch();
  }

  void _updateScanTip() {
    final tips = [
      'Ensure good lighting for better scanning',
      'Hold the camera steady and keep barcode flat',
      'Try using the torch in low light conditions',
      'Make sure the barcode is clear and not damaged',
      'Keep the barcode within the scanning frame',
    ];
    setState(() {
      _currentScanTip = tips[DateTime.now().millisecond % tips.length];
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Permission Required',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Camera permission is required to scan barcodes. Please enable it in app settings.',
          style: GoogleFonts.ubuntu(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.ubuntu(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Product Not Found',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'The product with barcode $barcode was not found in our database.\n\nPlease try scanning again or search manually.',
          style: GoogleFonts.ubuntu(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.ubuntu(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBarcodeNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Barcode Not Detected',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Could not detect a barcode in the image. Please try again with a clearer image or use the camera scanner.',
          style: GoogleFonts.ubuntu(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.ubuntu(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Error',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Failed to fetch product information: $error',
          style: GoogleFonts.ubuntu(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.ubuntu(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEducationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const UserEducationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_permissionStatus != CameraPermissionStatus.granted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: CameraPermissionWidget(
          status: _permissionStatus,
          onRequestPermission: _requestPermission,
          onOpenSettings: _openSettings,
          onPickFromGallery: _pickFromGallery,
          onShowEducation: _showEducationSheet,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: _controller,
              onDetect: _onBarcodeDetected,
            ),

            // Overlay with scanning area
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Scan Barcode',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Point camera at product barcode',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Info/Education button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        onPressed: _showEducationSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Control buttons (torch, manual capture, gallery)
            Positioned(
              right: 16.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Torch toggle
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: _isTorchOn ? AppColors.primary : Colors.white,
                        ),
                        onPressed: _toggleTorch,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Gallery button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        onPressed: _pickFromGallery,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Fetching product information...',
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Instructions at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scanning tip
                    if (_currentScanTip != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                _currentScanTip!,
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_currentScanTip == null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Align barcode within the frame',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Scanning area (center rectangle)
    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    final scanArea = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );

    // Create hole in overlay
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanArea,
          const Radius.circular(20),
        ),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      path,
      holePath,
    );

    canvas.drawPath(overlayPath, paint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;
    final cornerRadius = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft + cornerRadius, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerRadius),
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize - cornerRadius, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerRadius),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + cornerRadius, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + scanAreaSize - cornerRadius, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerRadius),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
