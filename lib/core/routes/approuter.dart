import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/pages/screen_loginpage.dart';
import 'package:crisant_connect/features/authentication/pages/screen_otppage.dart';
import 'package:crisant_connect/features/authentication/pages/screen_splashpage.dart';
import 'package:crisant_connect/features/dashboard/pages/navigation_shell.dart';
import 'package:crisant_connect/features/notifications/pages/screen_notifications.dart';
import 'package:crisant_connect/features/profile/pages/screen_profile.dart';

import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Approtes.splash,

    routes: [
      /// Splash
      GoRoute(
        path: Approtes.splash,
        builder: (context, state) => SplashScreen(),
      ),

      /// Login
      GoRoute(
        path: Approtes.login,
        builder: (context, state) => const ScreenLoginPage(),
      ),

      /// OTP
      GoRoute(
        path: Approtes.otp,
        builder: (context, state) {
          final mobileNumber = state.extra is String
              ? state.extra as String
              : null;

          return ScreenOtpPage(mobileNumber: mobileNumber);
        },
      ),

      /// Dashboard
      GoRoute(
        path: Approtes.dashboard,
        builder: (context, state) => const NavigationShell(),
      ),

      /// Profile
      GoRoute(
        path: Approtes.profile,
        builder: (context, state) => const ScreenProfile(),
      ),

      /// Notifications
      GoRoute(
        path: Approtes.notifications,
        builder: (context, state) => const ScreenNotifications(),
      ),

      // // /// Main Page
      // GoRoute(
      //   path: Approtes.main,
      //   pageBuilder: (context, state) {
      //     return CustomTransitionPage(
      //       key: state.pageKey,
      //       child: const ScreenMainPage(),
      //       transitionsBuilder:
      //           (context, animation, secondaryAnimation, child) {
      //             return FadeTransition(opacity: animation, child: child);
      //           },
      //     );
      //   },
      // ),
    ],
  );
}
