import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialPlatformIcon extends StatelessWidget {
  final String platform;
  final double size;
  final Color fallbackColor;

  const SocialPlatformIcon({
    super.key,
    required this.platform,
    required this.size,
    this.fallbackColor = const Color(0xFF3F5D62),
  });

  @override
  Widget build(BuildContext context) {
    final asset = _assetForPlatform(platform);
    if (asset == null) {
      return Icon(Icons.public_rounded, color: fallbackColor, size: size);
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  static String? _assetForPlatform(String platform) {
    final normalized = platform.toLowerCase();
    if (normalized.contains('instagram')) {
      return 'assets/images/instagram.svg';
    }
    if (normalized.contains('facebook')) {
      return 'assets/images/facebook.svg';
    }
    return null;
  }
}
