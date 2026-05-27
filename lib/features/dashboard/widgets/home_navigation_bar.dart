import 'dart:ui';

import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:flutter/material.dart';

class HomeNavigationBar extends StatefulWidget {
  final ValueChanged<int> onPageChanged;
  final int selectedIndex;

  const HomeNavigationBar({
    super.key,
    required this.onPageChanged,
    this.selectedIndex = 0,
  });

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar> {
  late int _currentIndex;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.image_rounded, label: 'Gallery'),
    _NavItem(icon: Icons.add_circle_rounded, label: 'Create Post'),
    _NavItem(icon: Icons.article_rounded, label: 'Posts'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(HomeNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() => _currentIndex = widget.selectedIndex);
    }
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    widget.onPageChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.screenWidth;
    final navWidth = width < 460 ? width - ResponsiveUtils.wp(4) : 430.0;

    return SizedBox(
      height: ResponsiveUtils.hp(8.8).clamp(66, 74).toDouble(),
      width: navWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kprimarycolor.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.wp(2.2).clamp(7, 10).toDouble(),
              vertical: ResponsiveUtils.hp(0.9).clamp(6, 8).toDouble(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (index) {
                return _NavButton(
                  item: _items[index],
                  isSelected: index == _currentIndex,
                  onTap: () => _onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveUtils.screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        height: isSelected ? 58 : 48,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (compact ? 12 : 18) : (compact ? 8 : 10),
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Appcolors.kprimarycolor
              : Appcolors.kwhitecolor.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(isSelected ? 30 : 18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Appcolors.kprimarycolor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: isSelected ? 24 : 23,
              color: isSelected
                  ? Appcolors.kwhitecolor
                  : const Color(0xFF8A9AAD),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: Appcolors.kwhitecolor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
