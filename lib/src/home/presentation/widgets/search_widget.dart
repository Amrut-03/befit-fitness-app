import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:befit_fitness_app/core/constants/app_colors.dart';

/// Search widget for home screen
class SearchWidget extends StatefulWidget {
  final String email;
  final Function(String)? onCategorySelected;

  const SearchWidget({
    super.key,
    required this.email,
    this.onCategorySelected,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'Generate Workouts',
    'Calculator',
    'Nutrition',
  ];
  List<String> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = [];
      } else {
        _filteredCategories = _categories
            .where((category) =>
                category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToCategory(String category) {
    if (widget.onCategorySelected != null) {
      widget.onCategorySelected!(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: 16.w,
        left: 16.w,
      ),
      child: Column(
        children: [
          Container(
            height: 40.h,
            width: 350.w,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryDark),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: TextField(
              cursorColor: AppColors.primaryDark,
              controller: _searchController,
              onChanged: _filterCategories,
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: AppColors.primaryDark),
                prefixIcon: const Icon(
                  Icons.search_outlined,
                  color: AppColors.primaryDark,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          if (_filteredCategories.isNotEmpty) ...[
            Column(
              children: _filteredCategories.map((category) {
                return InkWell(
                  onTap: () => _navigateToCategory(category),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: ListTile(
                        leading: category == "Generate Workouts"
                            ? Image.asset(
                                'assets/home/icons/dumbbell.png',
                                scale: 20.w,
                              )
                            : category == "Calculator"
                                ? Image.asset(
                                    'assets/home/icons/calculator.png',
                                    scale: 20.w,
                                  )
                                : Image.asset(
                                    'assets/home/icons/plan.png',
                                    scale: 20.w,
                                  ),
                        trailing: const ClipOval(
                          child: Icon(
                            Icons.arrow_forward_ios_sharp,
                            size: 15,
                          ),
                        ),
                        title: Text(
                          category,
                          style: GoogleFonts.ubuntu(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else if (_searchController.text.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                'No results found',
                style: GoogleFonts.ubuntu(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

