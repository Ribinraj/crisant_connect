import 'package:crisant_connect/core/colors.dart';
import 'package:flutter/material.dart';

// ─── Replace with your actual import path ────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────

/// A full-screen background widget with animated coral geometric shapes.
/// Wrap any page's Scaffold body (or use as a Stack base) with this widget.
///
/// ```dart
/// // Usage 1 – Scaffold body
/// Scaffold(
///   body: AppBackground(
///     child: YourPageContent(),
///   ),
/// )
///
/// // Usage 2 – Stack
/// Stack(
///   children: [
///     const AppBackground(),
///     YourPageContent(),
///   ],
/// )
/// ```
class AppBackground extends StatelessWidget {
  final Widget? child;

  /// Overall opacity of the geometric layer (0.0 – 1.0).
  /// Lower values give a more subtle background. Default: 1.0
  final double opacity;

  const AppBackground({super.key, this.child, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Base warm cream fill ──────────────────────────────────────────
        Container(color: Appcolors.kbackgroundcolor),

        // ── Geometric shapes layer ────────────────────────────────────────
        Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: _GeometricBgPainter(),
            size: Size.infinite,
          ),
        ),

        // ── Page content ──────────────────────────────────────────────────
        ?child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _GeometricBgPainter extends CustomPainter {
  // Coral palette
  static const _solidCoral = Color(0xFFF37A65); // kprimarycolor
  static const _midCoral = Color(0xFFFFB89E); // kprimaryLightColor
  static const _palePerach = Color(0xFFFFF0E8); // near kbackgroundcolor
  static const _softOrange = Color(0xFFFF9E80); // ksecondarycolor

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── TOP-LEFT parallelogram (cream/pale, partially off-screen) ─────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(0, 0),
        Offset(w * 0.195, 0),
        Offset(w * 0.175, h * 0.115),
        Offset(0, h * 0.085),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_palePerach, _midCoral.withValues(alpha: 0.55)],
      ),
      rect: Rect.fromLTWH(0, 0, w * 0.2, h * 0.12),
    );

    // ── TOP-CENTER tall narrow parallelogram ──────────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(w * 0.215, 0),
        Offset(w * 0.465, 0),
        Offset(w * 0.44, h * 0.215),
        Offset(w * 0.195, h * 0.215),
      ],
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_midCoral.withValues(alpha: 0.45), _palePerach],
      ),
      rect: Rect.fromLTWH(w * 0.19, 0, w * 0.28, h * 0.22),
    );

    // ── TOP-RIGHT large coral block ───────────────────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(w * 0.635, 0),
        Offset(w, 0),
        Offset(w, h * 0.26),
        Offset(w * 0.595, h * 0.26),
        Offset(w * 0.61, h * 0.02),
      ],
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          _solidCoral.withValues(alpha: 0.85),
          _midCoral.withValues(alpha: 0.3),
        ],
      ),
      rect: Rect.fromLTWH(w * 0.59, 0, w * 0.41, h * 0.27),
    );

    // ── RIGHT EDGE thin strip ─────────────────────────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(w * 0.87, h * 0.26),
        Offset(w, h * 0.26),
        Offset(w, h * 0.32),
        Offset(w * 0.87, h * 0.305),
      ],
      gradient: LinearGradient(
        colors: [_midCoral.withValues(alpha: 0.25), _palePerach],
      ),
      rect: Rect.fromLTWH(w * 0.87, h * 0.26, w * 0.13, h * 0.06),
    );

    // ── BOTTOM-LEFT large coral hexagonal block ───────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(0, h * 0.78),
        Offset(w * 0.04, h * 0.765),
        Offset(w * 0.185, h * 0.84),
        Offset(w * 0.185, h),
        Offset(0, h),
      ],
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [_solidCoral, _midCoral.withValues(alpha: 0.5)],
      ),
      rect: Rect.fromLTWH(0, h * 0.76, w * 0.19, h * 0.24),
    );

    // ── BOTTOM-LEFT secondary lighter block ───────────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(0, h * 0.87),
        Offset(w * 0.22, h * 0.87),
        Offset(w * 0.22, h),
        Offset(0, h),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _midCoral.withValues(alpha: 0.55),
          _softOrange.withValues(alpha: 0.35),
        ],
      ),
      rect: Rect.fromLTWH(0, h * 0.87, w * 0.22, h * 0.13),
    );

    // ── BOTTOM-RIGHT small corner accent ──────────────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [Offset(w * 0.82, h), Offset(w, h * 0.955), Offset(w, h)],
      gradient: LinearGradient(
        colors: [
          _midCoral.withValues(alpha: 0.6),
          _solidCoral.withValues(alpha: 0.4),
        ],
      ),
      rect: Rect.fromLTWH(w * 0.82, h * 0.95, w * 0.18, h * 0.05),
    );

    // ── BOTTOM-LEFT shadow/echo parallelogram ─────────────────────────────
    _drawGradientPolygon(
      canvas,
      points: [
        Offset(0, h * 0.93),
        Offset(w * 0.28, h * 0.93),
        Offset(w * 0.24, h),
        Offset(0, h),
      ],
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_midCoral.withValues(alpha: 0.20), _palePerach],
      ),
      rect: Rect.fromLTWH(0, h * 0.93, w * 0.28, h * 0.07),
    );
  }

  void _drawGradientPolygon(
    Canvas canvas, {
    required List<Offset> points,
    required LinearGradient gradient,
    required Rect rect,
  }) {
    if (points.length < 3) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GeometricBgPainter _) => false;
}
