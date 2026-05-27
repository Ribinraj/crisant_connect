import 'package:crisant_connect/core/colors.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, warning, error }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    final snackbarConfig = _getSnackbarConfig(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: _SnackbarContent(message: message, config: snackbarConfig),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      action: onActionPressed != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: snackbarConfig.actionTextColor,
              onPressed: onActionPressed,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static _SnackbarConfig _getSnackbarConfig(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarConfig(
          backgroundColor: Appcolors.kgreencolor,
          iconColor: Appcolors.kwhitecolor,
          textColor: Appcolors.kwhitecolor,
          actionTextColor: Appcolors.kwhitecolor,
          icon: Icons.check_circle_outline,
          shadowColor: Appcolors.kgreencolor.withValues(alpha: 0.3),
        );
      case SnackbarType.warning:
        return _SnackbarConfig(
          backgroundColor: Appcolors.ksecondarycolor,
          iconColor: Appcolors.kwhitecolor,
          textColor: Appcolors.kwhitecolor,
          actionTextColor: Appcolors.kwhitecolor,
          icon: Icons.warning_amber_outlined,
          shadowColor: Appcolors.ksecondarycolor.withValues(alpha: 0.3),
        );
      case SnackbarType.error:
        return _SnackbarConfig(
          backgroundColor: Appcolors.kredcolor,
          iconColor: Appcolors.kwhitecolor,
          textColor: Appcolors.kwhitecolor,
          actionTextColor: Appcolors.kwhitecolor,
          icon: Icons.error_outline,
          shadowColor: Appcolors.kredcolor.withValues(alpha: 0.3),
        );
    }
  }
}

class _SnackbarConfig {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color actionTextColor;
  final IconData icon;
  final Color shadowColor;

  _SnackbarConfig({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.actionTextColor,
    required this.icon,
    required this.shadowColor,
  });
}

class _SnackbarContent extends StatefulWidget {
  final String message;
  final _SnackbarConfig config;

  const _SnackbarContent({required this.message, required this.config});

  @override
  State<_SnackbarContent> createState() => _SnackbarContentState();
}

class _SnackbarContentState extends State<_SnackbarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.config.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.config.shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Appcolors.kwhitecolor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      widget.config.icon,
                      color: widget.config.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.config.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
