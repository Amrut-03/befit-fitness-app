import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/food_storage_service.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/manual_food_entry_screen.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';

/// Screen to display all food items (manual and barcode scanned)
class MyFoodItemsScreen extends StatefulWidget {
  static const String route = '/my-food-items';

  const MyFoodItemsScreen({super.key});

  @override
  State<MyFoodItemsScreen> createState() => _MyFoodItemsScreenState();
}

class _MyFoodItemsScreenState extends State<MyFoodItemsScreen> {
  final FoodStorageService _storageService = FoodStorageService(
    firestore: FirebaseFirestore.instance,
  );
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _foodItems = []; // Contains: {docId, type: 'manual'|'scanned', product: FoodProduct}

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> allItems = [];

      // Load manual food items
      final manualCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('manualFilledFood')
          .collection('foodItems');

      final manualSnapshot = await manualCollection.get();
      for (var doc in manualSnapshot.docs) {
        final data = doc.data();
        final nutritionData = data['nutrition'] as Map<String, dynamic>? ?? {};
        
        final product = FoodProduct(
          barcode: data['barcode'] ?? '',
          name: data['name'] ?? 'Unknown',
          brand: data['brand'],
          imageUrl: data['imageUrl'],
          category: data['category'],
          ingredients: data['ingredients'],
          allergens: data['allergens'],
          nutrition: NutritionInfo(
            calories: nutritionData['calories']?.toDouble(),
            protein: nutritionData['protein']?.toDouble(),
            carbs: nutritionData['carbs']?.toDouble(),
            fat: nutritionData['fat']?.toDouble(),
            fiber: nutritionData['fiber']?.toDouble(),
            sugar: nutritionData['sugar']?.toDouble(),
            sodium: nutritionData['sodium']?.toDouble(),
            servingSize: nutritionData['servingSize']?.toDouble() ?? 100.0,
            servingUnit: nutritionData['servingUnit'] as String?,
          ),
        );

        allItems.add({
          'docId': doc.id,
          'type': 'manual',
          'product': product,
        });
      }

      // Load barcode scanned food items
      final scannedCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('foodItems')
          .doc('barcodeScannedFood')
          .collection('foodItems');

      final scannedSnapshot = await scannedCollection.get();
      for (var doc in scannedSnapshot.docs) {
        final data = doc.data();
        final nutritionData = data['nutrition'] as Map<String, dynamic>? ?? {};
        
        final product = FoodProduct(
          barcode: data['barcode'] ?? '',
          name: data['name'] ?? 'Unknown',
          brand: data['brand'],
          imageUrl: data['imageUrl'],
          category: data['category'],
          ingredients: data['ingredients'],
          allergens: data['allergens'],
          nutrition: NutritionInfo(
            calories: nutritionData['calories']?.toDouble(),
            protein: nutritionData['protein']?.toDouble(),
            carbs: nutritionData['carbs']?.toDouble(),
            fat: nutritionData['fat']?.toDouble(),
            fiber: nutritionData['fiber']?.toDouble(),
            sugar: nutritionData['sugar']?.toDouble(),
            sodium: nutritionData['sodium']?.toDouble(),
            servingSize: nutritionData['servingSize']?.toDouble() ?? 100.0,
            servingUnit: nutritionData['servingUnit'] as String?,
          ),
        );

        allItems.add({
          'docId': doc.id,
          'type': 'scanned',
          'product': product,
        });
      }

      // Sort by name
      allItems.sort((a, b) {
        final nameA = (a['product'] as FoodProduct).name.toLowerCase();
        final nameB = (b['product'] as FoodProduct).name.toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _foodItems = allItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading food items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteFoodItem(String docId, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Delete Food Item',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this food item?',
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
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('foodItems')
            .doc(type == 'manual' ? 'manualFilledFood' : 'barcodeScannedFood')
            .collection('foodItems');

        await collection.doc(docId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food item deleted successfully'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadFoodItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete food item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _renameFoodItem(String docId, String type, FoodProduct product) async {
    final controller = TextEditingController(text: product.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Rename Food Item',
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
            labelText: 'Food Name',
            labelStyle: GoogleFonts.ubuntu(color: Colors.white.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop(newName);
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

    if (result != null && result.isNotEmpty && result != product.name) {
      try {
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('foodItems')
            .doc(type == 'manual' ? 'manualFilledFood' : 'barcodeScannedFood')
            .collection('foodItems');

        await collection.doc(docId).update({
          'name': result,
          'normalizedName': _normalizeFoodName(result),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food item renamed successfully'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadFoodItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rename food item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateFoodItem(String docId, String type, FoodProduct product) async {
    // Navigate to manual food entry screen in edit mode
    final result = await context.push<FoodProduct>(
      ManualFoodEntryScreen.route,
      extra: {
        'product': product,
        'docId': docId,
        'type': type,
      },
    );

    if (result != null && mounted) {
      _loadFoodItems();
    }
  }

  String _normalizeFoodName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _showFoodItemDetails(String docId, String type, FoodProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodItemDetailsBottomSheet(
        docId: docId,
        type: type,
        product: product,
        onRename: () {
          Navigator.pop(context);
          _renameFoodItem(docId, type, product);
        },
        onUpdate: () {
          Navigator.pop(context);
          _updateFoodItem(docId, type, product);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteFoodItem(docId, type);
        },
      ),
    );
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
          'My Food Items',
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
          : _foodItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: 64.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No Food Items',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Add food items manually or scan barcodes',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFoodItems,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: EdgeInsets.all(20.w),
                    itemCount: _foodItems.length,
                    itemBuilder: (context, index) {
                      final item = _foodItems[index];
                      final docId = item['docId'] as String;
                      final type = item['type'] as String;
                      final product = item['product'] as FoodProduct;
                      return _buildFoodItemCard(docId, type, product);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodOptions,
        backgroundColor: AppColors.primary,
        icon: Icon(
          Icons.add,
          color: Colors.black,
          size: 24.sp,
        ),
        label: Text(
          'Add Food',
          style: GoogleFonts.ubuntu(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddFoodOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text(
              'Add Food Item',
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            // Scan Barcode option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push(BarcodeScannerScreen.route).then((_) {
                  // Reload food items after returning from scanner
                  _loadFoodItems();
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Scan Barcode',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Add Manually option
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push(ManualFoodEntryScreen.route).then((result) {
                  // Reload food items after returning from manual entry
                  if (result != null) {
                    _loadFoodItems();
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF4CAF50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: const Color(0xFF4CAF50),
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Add Manually',
                      style: GoogleFonts.ubuntu(
                        color: const Color(0xFF4CAF50),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(String docId, String type, FoodProduct product) {
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
          onTap: () {
            _showFoodItemDetails(docId, type, product);
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Food image or placeholder
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant_menu,
                                color: AppColors.primary,
                                size: 24.sp,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.restaurant_menu,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                ),
                SizedBox(width: 12.w),
                // Food details
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.name,
                              style: GoogleFonts.ubuntu(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: type == 'manual'
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              type == 'manual' ? 'Manual' : 'Scanned',
                              style: GoogleFonts.ubuntu(
                                color: type == 'manual' ? Colors.blue : Colors.green,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (product.brand != null && product.brand!.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          product.brand!,
                          style: GoogleFonts.ubuntu(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  color: Colors.black,
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _renameFoodItem(docId, type, product);
                        break;
                      case 'update':
                        _updateFoodItem(docId, type, product);
                        break;
                      case 'delete':
                        _deleteFoodItem(docId, type);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Rename',
                            style: GoogleFonts.ubuntu(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'update',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.update, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Update',
                            style: GoogleFonts.ubuntu(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Delete',
                            style: GoogleFonts.ubuntu(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to display food item details in read-only mode
class _FoodItemDetailsBottomSheet extends StatelessWidget {
  final String docId;
  final String type;
  final FoodProduct product;
  final VoidCallback onRename;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _FoodItemDetailsBottomSheet({
    required this.docId,
    required this.type,
    required this.product,
    required this.onRename,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Food Item Details',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.black,
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        onRename();
                        break;
                      case 'update':
                        onUpdate();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Rename',
                            style: GoogleFonts.ubuntu(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'update',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.update, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Update',
                            style: GoogleFonts.ubuntu(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Delete',
                            style: GoogleFonts.ubuntu(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Image
                  Center(
                    child: Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.restaurant_menu,
                                    color: AppColors.primary,
                                    size: 48.sp,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.restaurant_menu,
                              color: AppColors.primary,
                              size: 48.sp,
                            ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Food Name
                  _buildDetailRow(
                    label: 'Food Name',
                    value: product.name,
                    icon: Icons.restaurant_menu,
                  ),
                  SizedBox(height: 16.h),
                  // Type Badge
                  _buildDetailRow(
                    label: 'Type',
                    value: type == 'manual' ? 'Manual Entry' : 'Barcode Scanned',
                    icon: type == 'manual' ? Icons.edit : Icons.qr_code_scanner,
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _buildDetailRow(
                      label: 'Brand',
                      value: product.brand!,
                      icon: Icons.business,
                    ),
                  ],
                  if (product.category != null && product.category!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _buildDetailRow(
                      label: 'Category',
                      value: product.category!,
                      icon: Icons.category,
                    ),
                  ],
                  SizedBox(height: 24.h),
                  // Nutrition Information
                  Text(
                    'Nutritional Information',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildNutritionRow(
                          label: 'Calories',
                          value: product.nutrition.calories?.toStringAsFixed(0) ?? 'N/A',
                          unit: 'kcal',
                          icon: Icons.local_fire_department,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 12.h),
                        _buildNutritionRow(
                          label: 'Protein',
                          value: product.nutrition.protein?.toStringAsFixed(1) ?? 'N/A',
                          unit: 'g',
                          icon: Icons.fitness_center,
                          color: const Color(0xFF2196F3),
                        ),
                        SizedBox(height: 12.h),
                        _buildNutritionRow(
                          label: 'Carbohydrates',
                          value: product.nutrition.carbs?.toStringAsFixed(1) ?? 'N/A',
                          unit: 'g',
                          icon: Icons.grain,
                          color: const Color(0xFF4CAF50),
                        ),
                        SizedBox(height: 12.h),
                        _buildNutritionRow(
                          label: 'Fat',
                          value: product.nutrition.fat?.toStringAsFixed(1) ?? 'N/A',
                          unit: 'g',
                          icon: Icons.water_drop,
                          color: const Color(0xFFFF9800),
                        ),
                        if (product.nutrition.fiber != null) ...[
                          SizedBox(height: 12.h),
                          _buildNutritionRow(
                            label: 'Fiber',
                            value: product.nutrition.fiber!.toStringAsFixed(1),
                            unit: 'g',
                            icon: Icons.eco,
                            color: const Color(0xFF9C27B0),
                          ),
                        ],
                        if (product.nutrition.sugar != null) ...[
                          SizedBox(height: 12.h),
                          _buildNutritionRow(
                            label: 'Sugar',
                            value: product.nutrition.sugar!.toStringAsFixed(1),
                            unit: 'g',
                            icon: Icons.cake,
                            color: const Color(0xFFFFC107),
                          ),
                        ],
                        if (product.nutrition.sodium != null) ...[
                          SizedBox(height: 12.h),
                          _buildNutritionRow(
                            label: 'Sodium',
                            value: product.nutrition.sodium!.toStringAsFixed(0),
                            unit: 'mg',
                            icon: Icons.science,
                            color: const Color(0xFF00BCD4),
                          ),
                        ],
                        SizedBox(height: 12.h),
                        _buildNutritionRow(
                          label: 'Serving Size',
                          value: product.nutrition.servingSize?.toStringAsFixed(0) ?? 'N/A',
                          unit: product.nutrition.servingUnit ?? 'g',
                          icon: Icons.scale,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text(
                      'Ingredients',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.ingredients!,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                  if (product.allergens != null && product.allergens!.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text(
                      'Allergens',
                      style: GoogleFonts.ubuntu(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.allergens!,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                  if (product.barcode.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildDetailRow(
                      label: 'Barcode',
                      value: product.barcode,
                      icon: Icons.qr_code,
                    ),
                  ],
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.ubuntu(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
        ),
        Text(
          '$value $unit',
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
