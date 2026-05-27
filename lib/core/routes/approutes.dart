import 'package:flutter/material.dart';

class Approtes {
  /// Route observer for tracking navigation changes
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  //authpage
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/otppage';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const notifications = '/notifications';
}
