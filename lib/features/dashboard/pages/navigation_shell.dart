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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentPage,
            children: [
              const ScreenDashboard(),
              const ScreenGallery(),
              ScreenCreatePost(isActive: _currentPage == 2),
              ScreenPosts(isActive: _currentPage == 3),
            ],
          ),
          Positioned(
            bottom: ResponsiveUtils.hp(3.5).clamp(20, 30).toDouble(),
            left: 0,
            right: 0,
            child: Center(
              child: HomeNavigationBar(
                selectedIndex: _currentPage,
                onPageChanged: (index) => setState(() => _currentPage = index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
