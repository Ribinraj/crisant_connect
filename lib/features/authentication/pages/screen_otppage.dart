import 'dart:async';

import 'package:crisant_connect/core/appconstants.dart';
import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/blocs/verify_otp_bloc/verify_otp_bloc.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:crisant_connect/widgets/desktop_auth_layout.dart';
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

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  bool get _canResend => _secondsLeft == 0;
  String get _otp => _otpController.text;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    _otpController.dispose();
    _otpFocusNode.dispose();

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

  void _handleOtpChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      _otpController.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      return;
    }

    setState(() {});

    if (_otp.length == _otpLength) {
      _submitOtp();
    }
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

    _otpController.clear();

    _otpFocusNode.requestFocus();
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
              child: ResponsiveUtils.isDesktop(context)
                  ? DesktopAuthLayout(
                      title: 'Secure desktop\nverification',
                      subtitle:
                          'Confirm your sign-in and continue managing client content on a larger workspace.',
                      form: _OtpForm(
                        mobileNumber: mobileNumber,
                        hasMobileNumber: hasMobileNumber,
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        otpLength: _otpLength,
                        otp: _otp,
                        canResend: _canResend,
                        secondsLeft: _secondsLeft,
                        isLoading: isLoading,
                        onChanged: _handleOtpChanged,
                        onSubmit: _submitOtp,
                        onResend: _resendOtp,
                        showLogo: false,
                      ),
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _OtpForm(
                            mobileNumber: mobileNumber,
                            hasMobileNumber: hasMobileNumber,
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                            otpLength: _otpLength,
                            otp: _otp,
                            canResend: _canResend,
                            secondsLeft: _secondsLeft,
                            isLoading: isLoading,
                            onChanged: _handleOtpChanged,
                            onSubmit: _submitOtp,
                            onResend: _resendOtp,
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

class _OtpForm extends StatelessWidget {
  final String? mobileNumber;
  final bool hasMobileNumber;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int otpLength;
  final String otp;
  final bool canResend;
  final int secondsLeft;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final bool showLogo;

  const _OtpForm({
    required this.mobileNumber,
    required this.hasMobileNumber,
    required this.controller,
    required this.focusNode,
    required this.otpLength,
    required this.otp,
    required this.canResend,
    required this.secondsLeft,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmit,
    required this.onResend,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLogo) ...[
          Center(child: _LogoCard()),
          const SizedBox(height: 28),
        ],
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
        _OtpInput(
          controller: controller,
          focusNode: focusNode,
          length: otpLength,
          onChanged: onChanged,
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading || otp.length != otpLength ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolors.kprimarycolor,
              foregroundColor: Appcolors.kwhitecolor,
              disabledBackgroundColor: Appcolors.kprimaryLightColor.withValues(
                alpha: 0.6,
              ),
              disabledForegroundColor: Appcolors.kwhitecolor.withValues(
                alpha: 0.75,
              ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: canResend ? onResend : null,
          child: Text(
            canResend ? 'Resend OTP' : 'Resend OTP in $secondsLeft seconds',
            style: TextStyle(
              color: canResend ? Appcolors.kprimarycolor : Appcolors.ktextlight,
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
    );
  }
}

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(Appconstants.applogo, fit: BoxFit.contain, height: 120);
  }
}

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ValueChanged<String> onChanged;

  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focusNode.requestFocus,
      child: SizedBox(
        height: isDesktop ? 68 : 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([controller, focusNode]),
                builder: (context, _) {
                  final text = controller.text;
                  return Row(
                    children: [
                      for (var index = 0; index < length; index++) ...[
                        if (index > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _OtpDisplayBox(
                            digit: index < text.length ? text[index] : '',
                            active:
                                focusNode.hasFocus &&
                                (index == text.length ||
                                    (text.length == length &&
                                        index == length - 1)),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Positioned.fill(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: length,
                enableSuggestions: false,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(length),
                ],
                onChanged: onChanged,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpDisplayBox extends StatelessWidget {
  final String digit;
  final bool active;

  const _OtpDisplayBox({required this.digit, required this.active});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final borderColor = active
        ? Appcolors.kprimarycolor
        : Appcolors.kprimaryLightColor.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: active ? 1.8 : 1.4),
      ),
      child: Center(
        child: Text(
          digit,
          style: TextStyle(
            color: Appcolors.ktextdark,
            fontSize: isDesktop ? 26 : 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
