import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/widgets/activity_item.dart';
import 'package:befit_fitness_app/src/activity_tracking/data/services/location_tracking_service.dart';
import 'package:befit_fitness_app/src/activity_tracking/domain/models/activity_tracking_data.dart';
import 'package:befit_fitness_app/src/activity_tracking/data/utils/map_style.dart';
import 'package:befit_fitness_app/src/activity_tracking/data/utils/custom_marker_icon.dart';
import 'dart:ui';

/// Screen for tracking activities with map
class ActivityTrackingScreen extends StatefulWidget {
  static const String route = '/activity-tracking';
  
  final Activity activity;

  const ActivityTrackingScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  GoogleMapController? _mapController;
  bool _isTracking = false;
  bool _isPaused = false;
  Timer? _updateTimer;
  
  LatLng? _currentLocation;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  ActivityTrackingData? _trackingData;
  BitmapDescriptor? _customMarkerIcon;
  bool _useProfileImage = true; // Toggle between profile image and walking man

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadCustomMarker();
  }

  Future<void> _loadCustomMarker() async {
    try {
      final profileImageUrl = CustomMarkerIcon.getUserProfileImageUrl();
      final marker = await CustomMarkerIcon.createCustomMarker(
        profileImageUrl: profileImageUrl,
        activityColor: widget.activity.color,
        useProfileImage: _useProfileImage,
      );
      if (mounted) {
        setState(() {
          _customMarkerIcon = marker;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom marker: $e');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMapCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _updateMapCamera() {
    if (mounted && _mapController != null && _currentLocation != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentLocation!,
            16.0,
          ),
        );
      } catch (e) {
        // Ignore errors if controller is disposed
        debugPrint('Error updating map camera: $e');
      }
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _isPaused = false;
    });

    _locationService.startTracking(
      onLocationUpdate: (position) {
        if (!mounted) return;
        
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          
          // Update tracking data
          _trackingData = _locationService.getTrackingData();
          
          // Update polyline with modern styling
          if (_trackingData != null && _trackingData!.pathPoints.length > 1) {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('tracking_path'),
                points: _trackingData!.pathPoints
                    .map((point) => LatLng(point.latitude, point.longitude))
                    .toList(),
                color: widget.activity.color,
                width: 6,
                patterns: [],
                jointType: JointType.round,
                endCap: Cap.roundCap,
                startCap: Cap.roundCap,
              ),
            );
          }

          // Update marker for current position with custom icon
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentLocation!,
              icon: _customMarkerIcon ?? 
                  BitmapDescriptor.defaultMarkerWithHue(
                    _getMarkerHue(widget.activity.color),
                  ),
              anchor: const Offset(0.5, 0.5),
              flat: true, // Make marker flat to the map
            ),
          );
        });

        // Update camera to follow user
        if (mounted && _mapController != null) {
          try {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(_currentLocation!),
            );
          } catch (e) {
            // Ignore errors if controller is disposed
            debugPrint('Error animating camera: $e');
          }
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
    );

    // Start timer to update UI every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _trackingData = _locationService.getTrackingData();
      });
    });
  }

  void _pauseTracking() {
    setState(() {
      _isPaused = true;
    });
    _locationService.stopTracking();
    _updateTimer?.cancel();
  }

  void _resumeTracking() {
    _startTracking();
  }

  void _stopTracking() {
    _locationService.stopTracking();
    _updateTimer?.cancel();
    
    final finalData = _locationService.getTrackingData();
    
    setState(() {
      _isTracking = false;
      _isPaused = false;
      _trackingData = finalData;
    });

    // Show summary dialog
    if (finalData != null && mounted) {
      _showSummaryDialog(finalData);
    }
  }

  void _showSummaryDialog(ActivityTrackingData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Activity Summary',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Distance', data.formattedDistance),
            SizedBox(height: 10.h),
            _buildSummaryRow('Duration', data.formattedDuration),
            SizedBox(height: 10.h),
            _buildSummaryRow('Calories', '${data.formattedCalories} kcal'),
            SizedBox(height: 10.h),
            _buildSummaryRow('Avg Speed', data.formattedAverageSpeed),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text(
              'Done',
              style: GoogleFonts.ubuntu(
                color: widget.activity.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.ubuntu(
            color: Colors.white70,
            fontSize: 16.sp,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _getMarkerHue(Color color) {
    // Convert color to HSV and return hue
    final hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  @override
  void dispose() {
    _locationService.dispose();
    _updateTimer?.cancel();
    _updateTimer = null;
    if (_mapController != null) {
      try {
        _mapController!.dispose();
      } catch (e) {
        debugPrint('Error disposing map controller: $e');
      }
      _mapController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            if (_currentLocation != null)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 16.0,
                ),
                onMapCreated: (controller) {
                  if (mounted) {
                    _mapController = controller;
                    // Apply custom dark map style
                    controller.setMapStyle(MapStyle.darkStyle);
                    if (_currentLocation != null) {
                      _updateMapCamera();
                    }
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                polylines: _polylines,
                markers: _markers,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Top bar with activity info - Modern glassmorphism design
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: widget.activity.color.withOpacity(0.3),
                          width: 1,
                        ),
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
                            onPressed: () {
                              if (_isTracking) {
                                _showStopConfirmation();
                              } else {
                                context.pop();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.activity.color,
                                widget.activity.color.withOpacity(0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.activity.color.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.activity.icon,
                            color: Colors.white,
                            size: 26.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.activity.name,
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (_isTracking)
                                Text(
                                  _isPaused ? 'Paused' : 'Tracking...',
                                  style: GoogleFonts.ubuntu(
                                    color: _isPaused
                                        ? Colors.orange
                                        : widget.activity.color,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isTracking)
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPaused
                                  ? Colors.orange
                                  : widget.activity.color,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isPaused
                                          ? Colors.orange
                                          : widget.activity.color)
                                      .withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 8.w),
                        // Toggle button for marker style
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _useProfileImage ? Icons.person : Icons.directions_walk,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            tooltip: _useProfileImage 
                                ? 'Switch to walking man' 
                                : 'Switch to profile image',
                            onPressed: () async {
                              setState(() {
                                _useProfileImage = !_useProfileImage;
                              });
                              await _loadCustomMarker();
                              // Update existing marker if tracking
                              if (_isTracking && _currentLocation != null) {
                                setState(() {
                                  _markers.clear();
                                  _markers.add(
                                    Marker(
                                      markerId: const MarkerId('current_location'),
                                      position: _currentLocation!,
                                      icon: _customMarkerIcon ?? 
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            _getMarkerHue(widget.activity.color),
                                          ),
                                      anchor: const Offset(0.5, 0.5),
                                      flat: true,
                                    ),
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Metrics overlay (when tracking) - Modern card design
            if (_isTracking && _trackingData != null)
              Positioned(
                top: 90.h,
                left: 16.w,
                right: 16.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.activity.color.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildModernMetricCard(
                            'Distance',
                            _trackingData!.formattedDistance,
                            Icons.straighten,
                            Colors.blue,
                          ),
                          Container(
                            width: 1,
                            height: 40.h,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          _buildModernMetricCard(
                            'Time',
                            _trackingData!.formattedDuration,
                            Icons.timer_outlined,
                            Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 40.h,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          _buildModernMetricCard(
                            'Calories',
                            _trackingData!.formattedCalories,
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Control buttons at bottom - Modern design
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.95),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _isTracking
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (_isPaused)
                                Expanded(
                                  child: _buildModernButton(
                                    onPressed: _resumeTracking,
                                    icon: Icons.play_arrow_rounded,
                                    label: 'Resume',
                                    color: widget.activity.color,
                                  ),
                                )
                              else
                                Expanded(
                                  child: _buildModernButton(
                                    onPressed: _pauseTracking,
                                    icon: Icons.pause_rounded,
                                    label: 'Pause',
                                    color: Colors.orange,
                                  ),
                                ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildModernButton(
                                  onPressed: _stopTracking,
                                  icon: Icons.stop_rounded,
                                  label: 'Stop',
                                  color: Colors.red,
                                  isOutlined: true,
                                ),
                              ),
                            ],
                          )
                        : _buildModernButton(
                            onPressed: _startTracking,
                            icon: Icons.play_arrow_rounded,
                            label: 'Start ${widget.activity.name}',
                            color: widget.activity.color,
                            isLarge: true,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMetricCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
    bool isLarge = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isLarge ? 28.sp : 22.sp),
        label: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: isLarge ? 18.sp : 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: EdgeInsets.symmetric(
            vertical: isLarge ? 18.h : 16.h,
            horizontal: isLarge ? 24.w : 16.w,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isLarge ? 28.sp : 22.sp),
        label: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: isLarge ? 18.sp : 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isLarge ? 18.h : 16.h,
            horizontal: isLarge ? 32.w : 16.w,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Stop Tracking?',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to stop tracking? Your progress will be saved.',
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
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stopTracking();
            },
            child: Text(
              'Stop',
              style: GoogleFonts.ubuntu(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

