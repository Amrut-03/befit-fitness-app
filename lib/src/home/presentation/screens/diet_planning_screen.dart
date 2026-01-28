import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/plan_your_diet_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/diet_plan_detail_screen.dart';

/// Screen for viewing saved diet plans
class DietPlanningScreen extends StatefulWidget {
  static const String route = '/diet-planning';

  const DietPlanningScreen({super.key});

  @override
  State<DietPlanningScreen> createState() => _DietPlanningScreenState();
}

class _DietPlanningScreenState extends State<DietPlanningScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _dietPlans = [];

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadDietPlans();
  }

  Future<void> _loadDietPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dietPlan')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _dietPlans = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading diet plans: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDietPlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Delete Diet Plan',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this diet plan?',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Check if this is the active plan and clear it from dailyGoal
        final now = DateTime.now();
        final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final dailyGoalDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dailyGoals')
            .doc(dateString)
            .get();
        
        if (dailyGoalDoc.exists) {
          final data = dailyGoalDoc.data();
          final activePlanId = data?['dietPlanId'] as String?;
          if (activePlanId == planId) {
            // This is the active plan - clear it from dailyGoal
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .collection('dailyGoals')
                .doc(dateString)
                .set({
              'dietPlanId': null,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .doc(planId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Diet plan deleted successfully'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadDietPlans();
          // If this was the active plan, notify home page to refresh when user navigates back
          // We don't auto-pop, but the home page will refresh via didChangeDependencies
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete diet plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  double _calculateTotalCalories(List<dynamic> meals) {
    double total = 0.0;
    for (var meal in meals) {
      final nutrition = meal['nutrition'] as Map<String, dynamic>?;
      if (nutrition != null) {
        total += (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  Future<void> _editDietPlan(String planId, Map<String, dynamic> plan) async {
    final result = await context.push<bool>(
      PlanYourDietScreen.route,
      extra: {
        'planId': planId,
        'planData': plan,
      },
    );
    // Refresh when returning from edit
    if (result == true) {
      _loadDietPlans();
      // Notify home page to refresh if this was the active plan
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final dailyGoalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString)
          .get();
      if (dailyGoalDoc.exists) {
        final data = dailyGoalDoc.data();
        final activePlanId = data?['dietPlanId'] as String?;
        if (activePlanId == planId) {
          // This was the active plan - notify home page to refresh
          // The home page will refresh via didChangeDependencies or navigation callback
        }
      }
    }
  }

  Future<void> _renameDietPlan(String planId, Map<String, dynamic> plan) async {
    final currentName = plan['name'] as String? ?? 'Untitled Plan';
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Rename Diet Plan',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.ubuntu(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Plan Name',
            labelStyle: GoogleFonts.ubuntu(color: Colors.white.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        // Check for duplicate name (excluding current plan)
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .where('name', isEqualTo: newName)
            .get();

        final duplicateDocs = snapshot.docs.where((doc) => doc.id != planId);
        if (duplicateDocs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('A diet plan with this name already exists'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Update the plan name
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .doc(planId)
            .update({
          'name': newName,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Diet plan renamed successfully'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadDietPlans();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rename diet plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeDietPlanStatus(String planId, Map<String, dynamic> plan) async {
    final currentStatus = plan['status'] as String? ?? 'active';
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';

    try {
      // Get today's date string for dailyGoal document
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final dailyGoalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dailyGoals')
          .doc(dateString);

      // If setting to active, deactivate all other plans first
      if (newStatus == 'active') {
        final allPlansSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('dietPlan')
            .get();

        // Deactivate all other plans
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in allPlansSnapshot.docs) {
          if (doc.id != planId) {
            final planData = doc.data();
            final planStatus = planData['status'] as String? ?? 'inactive';
            if (planStatus == 'active') {
              batch.update(doc.reference, {
                'status': 'inactive',
                'updatedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }
        await batch.commit();

        // Add dietPlanId to today's dailyGoal document
        await dailyGoalRef.set({
          'dietPlanId': planId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Setting to inactive - remove dietPlanId from dailyGoal
        await dailyGoalRef.set({
          'dietPlanId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Update the current plan status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dietPlan')
          .doc(planId)
          .update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'active' 
                ? 'Diet plan activated. Other plans have been deactivated.'
                : 'Diet plan status changed to ${newStatus}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadDietPlans();
        // Status change affects active plan - home page will refresh via didChangeDependencies when user navigates back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Diet Planning',
          style: GoogleFonts.ubuntu(
            color: AppColors.textOnPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _dietPlans.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDietPlans,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: EdgeInsets.all(20.w),
                    itemCount: _dietPlans.length,
                    itemBuilder: (context, index) {
                      return _buildDietPlanCard(_dietPlans[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "plan_your_diet_button",
        onPressed: () async {
          final result = await context.push<bool>(PlanYourDietScreen.route);
          // Refresh when returning from Plan Your Diet screen
          if (result == true) {
            _loadDietPlans();
          }
        },
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.restaurant_menu, color: Colors.black),
        label: Text(
          'Plan Your Diet',
          style: GoogleFonts.ubuntu(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDietPlanCard(Map<String, dynamic> plan) {
    final meals = plan['meals'] as List<dynamic>? ?? [];
    final totalCalories = _calculateTotalCalories(meals);
    final planName = plan['name'] as String? ?? 'Untitled Plan';
    final date = plan['date'] as String? ?? '';
    final createdAt = plan['createdAt'] as String? ?? '';
    final status = plan['status'] as String? ?? 'active';
    final isActive = status == 'active';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
          child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () async {
            final result = await context.push<bool>(
              DietPlanDetailScreen.route,
              extra: {
                'planId': plan['id'] as String,
                'planData': plan,
              },
            );
            // Refresh when returning from detail screen (after editing or consuming meals)
            if (result == true) {
              _loadDietPlans();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              planName,
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? const Color(0xFF4CAF50).withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.ubuntu(
                                color: isActive 
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                      color: Colors.black,
                      onSelected: (value) {
                        final planId = plan['id'] as String;
                        switch (value) {
                          case 'edit':
                            _editDietPlan(planId, plan);
                            break;
                          case 'delete':
                            _deleteDietPlan(planId);
                            break;
                          case 'rename':
                            _renameDietPlan(planId, plan);
                            break;
                          case 'status':
                            _changeDietPlanStatus(planId, plan);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Edit Plan',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.drive_file_rename_outline, color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Rename Plan',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.toggle_on, color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Change Status',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Delete',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.red,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.ubuntu(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primary,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${meals.length} meals',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Calories',
                            style: GoogleFonts.ubuntu(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${totalCalories.toStringAsFixed(0)} kcal',
                            style: GoogleFonts.ubuntu(
                              color: AppColors.primary,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.5),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80.sp,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No diet plans saved yet',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the button below to plan your diet',
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

}
