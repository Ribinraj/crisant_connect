import 'dart:async';

import 'package:crisant_connect/core/appconstants.dart';
import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/blocs/verify_otp_bloc/verify_otp_bloc.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ScreenOtpPage extends StatefulWidget {
  final String? mobileNumber;

  const ScreenOtpPage({super.key, this.mobileNumber});

  @override
  State<ScreenOtpPage> createState() => _ScreenOtpPageState();
}

class _ScreenOtpPageState extends State<ScreenOtpPage> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  bool get _canResend => _secondsLeft == 0;
  String get _otp => _controllers.map((controller) => controller.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }

      setState(() => _secondsLeft--);
    });
  }

  void _handleOtpChanged(String value, int index) {
    if (value.length > 1) {
      _fillOtp(value);
      return;
    }

    setState(() {});

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_otp.length == _otpLength) {
      _submitOtp();
    }
  }

  void _fillOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    for (var i = 0; i < _otpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }

    setState(() {});

    final nextIndex = digits.length >= _otpLength
        ? _otpLength - 1
        : digits.length;
    final safeNextIndex = nextIndex.clamp(0, _otpLength - 1);
    _focusNodes[safeNextIndex].requestFocus();

    if (_otp.length == _otpLength) {
      _submitOtp();
    }
  }

  KeyEventResult _handleBackspace(KeyEvent event, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }

    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].clear();
    setState(() {});

    return KeyEventResult.handled;
  }

  Future<void> _submitOtp() async {
    final mobileNumber = widget.mobileNumber?.trim() ?? "";
    if (_otp.length != _otpLength || mobileNumber.isEmpty) {
      if (mobileNumber.isEmpty) {
        CustomSnackbar.show(
          context,
          message: "Mobile number is missing. Please request OTP again.",
          type: SnackbarType.error,
        );
      }

      return;
    }

    final state = context.read<VerifyOtpBloc>().state;
    if (state is VerifyOtpLoading) return;

    FocusScope.of(context).unfocus();
    context.read<VerifyOtpBloc>().add(
      VerifyOtpRequested(mobileNumber: mobileNumber, otp: _otp),
    );
  }

  void _resendOtp() {
    if (!_canResend) return;

    for (final controller in _controllers) {
      controller.clear();
    }

    _focusNodes.first.requestFocus();
    _startTimer();

    CustomSnackbar.show(
      context,
      message: 'OTP resent successfully',
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobileNumber = widget.mobileNumber?.trim();
    final hasMobileNumber = mobileNumber != null && mobileNumber.isNotEmpty;

    return BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
      listener: (context, state) {
        if (state is VerifyOtpSuccess) {
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.success,
          );
          context.go(Approtes.dashboard);
        }

        if (state is VerifyOtpFailure) {
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is VerifyOtpLoading;

        return Scaffold(
          backgroundColor: Appcolors.kwhitecolor,
          body: AppBackground(
            opacity: 0.45,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _LogoCard()),
                        const SizedBox(height: 28),
                        const Text(
                          'Verify OTP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Appcolors.ktextdark,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasMobileNumber
                              ? 'Enter the 6 digit code sent to +91 $mobileNumber'
                              : 'Enter the 6 digit code sent to continue',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Appcolors.ktextlight,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Row(
                          children: [
                            for (
                              var index = 0;
                              index < _otpLength;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _OtpBox(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  onChanged: (value) =>
                                      _handleOtpChanged(value, index),
                                  onKeyEvent: (event) =>
                                      _handleBackspace(event, index),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading || _otp.length != _otpLength
                                ? null
                                : _submitOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolors.kprimarycolor,
                              foregroundColor: Appcolors.kwhitecolor,
                              disabledBackgroundColor: Appcolors
                                  .kprimaryLightColor
                                  .withValues(alpha: 0.6),
                              disabledForegroundColor: Appcolors.kwhitecolor
                                  .withValues(alpha: 0.75),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Appcolors.kwhitecolor,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: _canResend ? _resendOtp : null,
                          child: Text(
                            _canResend
                                ? 'Resend OTP'
                                : 'Resend OTP in $_secondsLeft seconds',
                            style: TextStyle(
                              color: _canResend
                                  ? Appcolors.kprimarycolor
                                  : Appcolors.ktextlight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text(
                            'Change mobile number',
                            style: TextStyle(
                              color: Appcolors.ktextlight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(Appconstants.applogo, fit: BoxFit.contain, height: 120);
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Focus(
        onKeyEvent: (_, event) => onKeyEvent(event),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(
            color: Appcolors.ktextdark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Appcolors.kwhitecolor.withValues(alpha: 0.92),
            contentPadding: EdgeInsets.zero,
            enabledBorder: _border(Appcolors.kprimaryLightColor, 0.7),
            focusedBorder: _border(Appcolors.kprimarycolor, 1),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double alpha) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color.withValues(alpha: alpha), width: 1.4),
    );
  }
}
