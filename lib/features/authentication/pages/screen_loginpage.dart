import 'package:crisant_connect/core/appconstants.dart';
import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/blocs/send_otp_bloc/send_otp_bloc.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:crisant_connect/widgets/desktop_auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ScreenLoginPage extends StatefulWidget {
  const ScreenLoginPage({super.key});

  @override
  State<ScreenLoginPage> createState() => _ScreenLoginPageState();
}

class _ScreenLoginPageState extends State<ScreenLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    context.read<SendOtpBloc>().add(
      SendOtpRequested(mobileNumber: _mobileController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SendOtpBloc, SendOtpState>(
      listener: (context, state) {
        if (state is SendOtpSuccess) {
          _showMessage(state.message);
          context.push(Approtes.otp, extra: state.response.mobileNumber);
        }

        if (state is SendOtpFailure) {
          _showMessage(state.message, isError: true);
        }
      },
      builder: (context, state) {
        final isLoading = state is SendOtpLoading;

        return Scaffold(
          backgroundColor: Appcolors.kwhitecolor,
          body: AppBackground(
            opacity: 0.45,
            child: SafeArea(
              child: ResponsiveUtils.isDesktop(context)
                  ? DesktopAuthLayout(
                      title: 'Welcome to\nCrisant Connect',
                      subtitle:
                          'Access your client content workspace from a focused desktop experience.',
                      form: _LoginForm(
                        formKey: _formKey,
                        controller: _mobileController,
                        isLoading: isLoading,
                        onSubmit: _handleContinue,
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
                          child: _LoginForm(
                            formKey: _formKey,
                            controller: _mobileController,
                            isLoading: isLoading,
                            onSubmit: _handleContinue,
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

  void _showMessage(String message, {bool isError = false}) {
    CustomSnackbar.show(
      context,
      message: message,
      type: isError ? SnackbarType.error : SnackbarType.success,
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool showLogo;

  const _LoginForm({
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            Center(child: _LogoCard()),
            const SizedBox(height: 28),
          ],
          const Text(
            'Welcome to Crisant Connect',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Appcolors.ktextdark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your mobile number to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Appcolors.ktextlight,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 36),
          _MobileNumberField(controller: controller),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimarycolor,
                foregroundColor: Appcolors.kwhitecolor,
                disabledBackgroundColor: Appcolors.kprimaryLightColor
                    .withValues(alpha: 0.6),
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
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'We will send an OTP to verify your number.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Appcolors.ktextlight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(Appconstants.applogo, fit: BoxFit.contain, height: 120);
  }
}

class _MobileNumberField extends StatelessWidget {
  final TextEditingController controller;

  const _MobileNumberField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final mobile = value?.trim() ?? '';

        if (mobile.isEmpty) {
          return 'Enter mobile number';
        }

        return null;
      },
      style: TextStyle(
        color: Appcolors.ktextdark,
        fontSize: isDesktop ? 19 : 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: Appcolors.kwhitecolor.withValues(alpha: 0.9),
        prefixIcon: Icon(Icons.phone_rounded, size: isDesktop ? 28 : 24),
        prefixIconColor: Appcolors.kprimarycolor,
        prefixText: '+91 ',
        prefixStyle: TextStyle(
          color: Appcolors.ktextdark,
          fontSize: isDesktop ? 19 : 16,
          fontWeight: FontWeight.w700,
        ),
        labelText: 'Mobile number',
        hintText: 'Enter 10 digit number',
        labelStyle: const TextStyle(
          color: Appcolors.kprimarycolor,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: Appcolors.ktextlight.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isDesktop ? 21 : 17,
        ),
        enabledBorder: _border(Appcolors.kprimaryLightColor, 0.48),
        focusedBorder: _border(Appcolors.kprimarycolor, 1),
        errorBorder: _border(Appcolors.kredcolor, 1),
        focusedErrorBorder: _border(Appcolors.kredcolor, 1),
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
