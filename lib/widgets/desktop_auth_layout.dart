import 'package:crisant_connect/core/appconstants.dart';
import 'package:crisant_connect/core/colors.dart';
import 'package:flutter/material.dart';

class DesktopAuthLayout extends StatelessWidget {
  final Widget form;
  final String title;
  final String subtitle;

  const DesktopAuthLayout({
    super.key,
    required this.form,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280, minHeight: 640),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _BrandPanel(title: title, subtitle: subtitle),
              ),
              const SizedBox(width: 64),
              Expanded(
                flex: 6,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: form,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BrandPanel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 590),
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Appcolors.kprimaryLightColor.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(Appconstants.applogo, fit: BoxFit.contain, height: 104),
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            height: 210,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6F3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD5C9)),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: 12,
                  top: 12,
                  child: _BrandShape(
                    width: 126,
                    height: 88,
                    color: Appcolors.kprimaryLightColor.withValues(alpha: 0.36),
                  ),
                ),
                Positioned(
                  left: 32,
                  bottom: 28,
                  child: _BrandShape(
                    width: 118,
                    height: 76,
                    color: Appcolors.kprimarycolor.withValues(alpha: 0.16),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: Appcolors.kprimarycolor,
                    size: 86,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Text(
            title,
            style: const TextStyle(
              color: Appcolors.ktextdark,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Appcolors.ktextlight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _BrandShape({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
