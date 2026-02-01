import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';
import 'package:befit_fitness_app/core/widgets/shimmer_widget.dart';
import 'package:befit_fitness_app/src/food_scanner/domain/models/food_product.dart';
import 'package:befit_fitness_app/src/food_scanner/data/services/food_storage_service.dart';
import 'package:befit_fitness_app/src/food_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:befit_fitness_app/src/home/presentation/screens/manual_food_entry_screen.dart';

/// Bottom sheet for adding food items with multiple selection support
void showAddFoodBottomSheet(BuildContext context, Function(List<FoodProduct>) onFoodSelected) {
  showModalBottomSheet(
    backgroundColor: Colors.black,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext bottomSheetContext) {
      return _AddFoodBottomSheetContent(
        parentContext: context,
        bottomSheetContext: bottomSheetContext,
        onFoodSelected: (products) {
          onFoodSelected(products);
        },
      );
    },
  );
}

class _AddFoodBottomSheetContent extends StatefulWidget {
  final BuildContext parentContext;
  final BuildContext bottomSheetContext;
  final Function(List<FoodProduct>) onFoodSelected;

  const _AddFoodBottomSheetContent({
    required this.parentContext,
    required this.bottomSheetContext,
    required this.onFoodSelected,
  });

  @override
  State<_AddFoodBottomSheetContent> createState() => _AddFoodBottomSheetContentState();
}

class _AddFoodBottomSheetContentState extends State<_AddFoodBottomSheetContent> {
  final FoodStorageService _storageService = FoodStorageService(
    firestore: FirebaseFirestore.instance,
  );

  List<FoodProduct> _foodItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _selectedFoodIds = {}; // Track selected food items by ID

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
      final items = await _storageService.getAllFoodProducts();
      if (mounted) {
        setState(() {
          _foodItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<FoodProduct> get _filteredFoodItems {
    if (_searchQuery.isEmpty) {
      return _foodItems;
    }
    return _foodItems.where((item) {
      final name = item.name.toLowerCase();
      final brand = item.brand?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || brand.contains(query);
    }).toList();
  }

  Future<void> _handleScanBarcode() async {
    if (!mounted) return;
    // Navigate first - this will automatically close the bottom sheet
    if (widget.parentContext.mounted) {
      await widget.parentContext.push(BarcodeScannerScreen.route);
    }
  }

  Future<void> _handleAddManually() async {
    if (!mounted) return;
    // Navigate first - this will automatically close the bottom sheet
    if (widget.parentContext.mounted) {
      final result = await widget.parentContext.push<FoodProduct?>(ManualFoodEntryScreen.route);
      if (result != null && mounted) {
        // Call callback after navigation returns with single item in list
        widget.onFoodSelected([result]);
      }
    }
  }

  void _toggleFoodSelection(FoodProduct product) {
    setState(() {
      final productId = product.barcode.isNotEmpty ? product.barcode : product.name;
      if (_selectedFoodIds.contains(productId)) {
        _selectedFoodIds.remove(productId);
      } else {
        _selectedFoodIds.add(productId);
      }
    });
  }

  bool _isFoodSelected(FoodProduct product) {
    final productId = product.barcode.isNotEmpty ? product.barcode : product.name;
    return _selectedFoodIds.contains(productId);
  }

  void _addSelectedFoods() {
    if (_selectedFoodIds.isEmpty) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('Please select at least one food item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedFoods = _foodItems.where((food) {
      final productId = food.barcode.isNotEmpty ? food.barcode : food.name;
      return _selectedFoodIds.contains(productId);
    }).toList();

    Navigator.of(widget.bottomSheetContext).pop();
    widget.onFoodSelected(selectedFoods);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w,
        right: 20.w,
        top: 12.h,
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Food',
                    style: GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedFoodIds.isNotEmpty)
                    Text(
                      '${_selectedFoodIds.length} selected',
                      style: GoogleFonts.ubuntu(
                        color: AppColors.primary,
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  if (_selectedFoodIds.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFoodIds.clear();
                        });
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(widget.bottomSheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                  color: AppColors.primary,
                  onTap: _handleScanBarcode,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Add Manually',
                  color: const Color(0xFF4CAF50),
                  onTap: _handleAddManually,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: GoogleFonts.ubuntu(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search food items...',
              hintStyle: GoogleFonts.ubuntu(
                color: Colors.white.withOpacity(0.5),
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Food items list
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: 6,
                    itemBuilder: (_, __) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: ShimmerLoading(
                        child: Container(
                          height: 64.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  )
                : _filteredFoodItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fastfood,
                              size: 64.sp,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No food items saved yet'
                                  : 'No items found',
                              style: GoogleFonts.ubuntu(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFoodItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredFoodItems[index];
                          return _buildFoodItemCard(item);
                        },
                      ),
          ),
          
          // Add Selected Button
          if (_selectedFoodIds.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addSelectedFoods,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Add ${_selectedFoodIds.length} Food${_selectedFoodIds.length > 1 ? 's' : ''}',
                    style: GoogleFonts.ubuntu(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.ubuntu(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(FoodProduct product) {
    final isSelected = _isFoodSelected(product);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primary.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected 
              ? AppColors.primary
              : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: product.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  width: 50.w,
                  height: 50.h,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                ),
              )
            : Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.fastfood,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
        title: Text(
          product.name,
          style: GoogleFonts.ubuntu(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: product.brand != null
            ? Text(
                product.brand!,
                style: GoogleFonts.ubuntu(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              )
            : null,
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) {
            _toggleFoodSelection(product);
          },
          activeColor: AppColors.primary,
          checkColor: Colors.black,
        ),
        onTap: () {
          _toggleFoodSelection(product);
        },
      ),
    );
  }
}
