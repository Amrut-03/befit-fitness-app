import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Discover section widget with 6 cards in a 3x2 grid
class DiscoverSection extends StatelessWidget {
  final Function(String)? onCardTap;

  const DiscoverSection({
    super.key,
    this.onCardTap,
  });

  // List of discover cards data
  final List<Map<String, dynamic>> _discoverCards = const [
    {
      'icon': Icons.nightlight_round,
      'title': 'Diet Plan',
      'subtitle': 'Eat right, sleep tight',
      'key': 'Diet Plan',
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Workout Plan',
      'subtitle': 'Cook, eat, log, repeat',
      'key': 'Workout Plan',
    },
    {
      'icon': Icons.qr_code_scanner,
      'title': 'Bar Code Scanner',
      'subtitle': 'Scan food products',
      'key': 'Bar Code Scanner',
    },
    {
      'icon': Icons.apps,
      'title': 'track Progress',
      'subtitle': 'Link apps & devices',
      'key': 'Track Progress',
    },
    {
      'icon': Icons.people,
      'title': 'Friends',
      'subtitle': 'Your support squad',
      'key': 'Friends',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'title': 'Community',
      'subtitle': 'Food & fitness inspo',
      'key': 'Community',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _discoverCards.length,
      itemBuilder: (context, index) {
        final card = _discoverCards[index];
        return _DiscoverCard(
          icon: card['icon'] as IconData,
          title: card['title'] as String,
          subtitle: card['subtitle'] as String,
          onTap: () => onCardTap?.call(card['key'] as String),
        );
      },
    );
  }
}

/// Individual discover card widget
class _DiscoverCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DiscoverCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80.h,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue icon
            Icon(
              icon,
              color: const Color(0xFF2196F3), // Blue color
              size: 28.sp,
            ),
            SizedBox(height: 10.h),
            // Title
            Text(
              title,
              style: GoogleFonts.ubuntu(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            // Subtitle
            Expanded(
              child: Text(
                subtitle,
                style: GoogleFonts.ubuntu(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

