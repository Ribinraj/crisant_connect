import 'package:crisant_connect/core/appconstants.dart';
import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/local_storage.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/blocs/refresh_token_bloc/refresh_token_bloc.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// BorderRadiusStyles
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _bgRippleCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _pillCtrl;
  late final AnimationController _pulseCtrl;

  // ── Animations ───────────────────────────────────────────────────────────
  late final Animation<double> _bgRipple;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _pillFade;
  late final Animation<Offset> _pillSlide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Background ripple (0 → 1 over 900 ms)
    _bgRippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bgRipple = CurvedAnimation(parent: _bgRippleCtrl, curve: Curves.easeOut);

    // Logo pop-in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _logoScale = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // Tagline slide-up
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn));
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    // Bottom pill / version badge
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pillFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.easeIn));
    _pillSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.easeOut));

    // Continuous heartbeat pulse on logo glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _bgRippleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _pillCtrl.forward();

    // ── Check stored session after 3 s total ─────────────────────────────
    await Future.delayed(const Duration(milliseconds: 2000));
    await _finishStartup();
  }

  Future<void> _finishStartup() async {
    final refreshToken = await LocalStorage.getRefreshToken();

    if (!mounted) return;

    if (refreshToken.isEmpty) {
      context.go(Approtes.login);
      return;
    }

    context.read<RefreshTokenBloc>().add(
      RefreshTokenRequested(refreshToken: refreshToken),
    );
  }

  Future<void> _clearSessionAndGoToLogin(BuildContext context) async {
    await LocalStorage.clearAll();
    if (!context.mounted) return;
    context.go(Approtes.login);
  }

  void _goToDashboard(BuildContext context) {
    if (!context.mounted) return;
    context.go(Approtes.dashboard);
  }

  @override
  void dispose() {
    _bgRippleCtrl.dispose();
    _logoCtrl.dispose();
    _taglineCtrl.dispose();
    _pillCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<RefreshTokenBloc, RefreshTokenState>(
      listener: (context, state) {
        if (state is RefreshTokenSuccess) {
          _goToDashboard(context);
        }

        if (state is RefreshTokenFailure) {
          _clearSessionAndGoToLogin(context);
        }
      },
      child: Scaffold(
        backgroundColor: Appcolors.kwhitecolor,
        body: AppBackground(
          opacity: 0.45,
          child: Stack(
            fit: StackFit.expand,
            children: [_buildRipple(), _buildContent(), _buildBottomPill()],
          ),
        ),
      ),
    );
  }

  // ── Ripple burst on entry ────────────────────────────────────────────────
  Widget _buildRipple() {
    return AnimatedBuilder(
      animation: _bgRipple,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final maxRadius = size.longestSide * 1.2;
        return CustomPaint(
          painter: _RipplePainter(
            progress: _bgRipple.value,
            maxRadius: maxRadius,
          ),
        );
      },
    );
  }

  // ── Logo + app name + tagline ────────────────────────────────────────────
  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glow halo behind logo
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Appcolors.kprimarycolor.withValues(
                      alpha: 0.18 * _pulse.value,
                    ),
                    blurRadius: 42 * _pulse.value,
                    spreadRadius: 6 * _pulse.value,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: SlideTransition(
            position: _logoSlide,
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(scale: _logoScale, child: _logoCard()),
            ),
          ),
        ),

        ResponsiveSizedBox.height20,

        // App name
        SlideTransition(
          position: _taglineSlide,
          child: FadeTransition(
            opacity: _taglineFade,
            child: Column(
              children: [
                TextStyles.headline(
                  text: 'Crisant Connect',
                  color: Appcolors.ktextdark,
                ),
                ResponsiveSizedBox.height5,
                TextStyles.caption(
                  text: 'Bridging People · Empowering Lives',
                  color: Appcolors.ktextlight,
                ),
              ],
            ),
          ),
        ),

        ResponsiveSizedBox.height40,

        // Loading indicator
        FadeTransition(
          opacity: _taglineFade,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Appcolors.kprimarycolor.withValues(alpha: 0.80),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Logo card widget ─────────────────────────────────────────────────────
  Widget _logoCard() {
    return Image.asset(Appconstants.applogo, fit: BoxFit.contain, height: 120);
  }

  // ── Bottom version pill ──────────────────────────────────────────────────
  Widget _buildBottomPill() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 36),
        child: SlideTransition(
          position: _pillSlide,
          child: FadeTransition(
            opacity: _pillFade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.82),
                borderRadius: BorderRadiusStyles.kradius30(),
                border: Border.all(
                  color: Appcolors.kprimaryLightColor.withValues(alpha: 0.45),
                ),
              ),
              child: TextStyles.caption(
                text: 'Version 1.0.0',
                color: Appcolors.ktextlight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Expanding ripple burst from centre on app launch.
class _RipplePainter extends CustomPainter {
  final double progress;
  final double maxRadius;

  const _RipplePainter({required this.progress, required this.maxRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final delay = i * 0.18;
      final p = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;

      final radius = maxRadius * p * 0.9;
      final opacity = (1 - p) * 0.12;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Appcolors.kprimarycolor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
