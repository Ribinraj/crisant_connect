import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/features/dashboard/pages/screen_dashboard.dart';
import 'package:crisant_connect/features/dashboard/widgets/home_navigation_bar.dart';
import 'package:crisant_connect/features/gallery/pages/screen_gallery.dart';
import 'package:crisant_connect/features/posts/ppages/screen_create_post.dart';
import 'package:crisant_connect/features/posts/ppages/screen_posts.dart';
import 'package:flutter/material.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final pages = [
      const ScreenDashboard(),
      const ScreenGallery(),
      ScreenCreatePost(isActive: _currentPage == 2),
      ScreenPosts(isActive: _currentPage == 3),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      body: isDesktop
          ? Row(
              children: [
                _DesktopNavigationRail(
                  selectedIndex: _currentPage,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                ),
                Expanded(
                  child: IndexedStack(index: _currentPage, children: pages),
                ),
              ],
            )
          : Stack(
              children: [
                IndexedStack(index: _currentPage, children: pages),
                Positioned(
                  bottom: ResponsiveUtils.hp(3.5).clamp(20, 30).toDouble(),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: HomeNavigationBar(
                      selectedIndex: _currentPage,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DesktopNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  const _DesktopNavigationRail({
    required this.selectedIndex,
    required this.onPageChanged,
  });

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.image_rounded, 'Gallery'),
    (Icons.add_circle_rounded, 'Create Post'),
    (Icons.article_rounded, 'Posts'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      right: false,
      child: Container(
        width: 124,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
          border: Border(
            right: BorderSide(
              color: Appcolors.kprimaryLightColor.withValues(alpha: 0.34),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Appcolors.kblackcolor.withValues(alpha: 0.025),
              blurRadius: 18,
              offset: const Offset(6, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Appcolors.kprimaryLightColor.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Appcolors.kprimarycolor,
                size: 32,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Tooltip(
                      message: item.$2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onPageChanged(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: selected
                                ? Appcolors.kprimarycolor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.$1,
                                color: selected
                                    ? Appcolors.kwhitecolor
                                    : const Color(0xFF8A9AAD),
                                size: 30,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected
                                      ? Appcolors.kwhitecolor
                                      : const Color(0xFF66758A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
