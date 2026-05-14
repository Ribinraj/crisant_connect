import 'dart:ui';

import 'package:crisant_connect/core/colors.dart';
import 'package:dhani_communications/core/appconstants.dart';
import 'package:dhani_communications/core/colors.dart';
import 'package:dhani_communications/core/responsiveutils.dart';
import 'package:dhani_communications/features/auth/blocs/send_otp_bloc/send_otp_bloc.dart';
import 'package:dhani_communications/widgets/custom_textfiield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<SendOtpBloc>().add(
            SendOtpButtonClickEvent(mobileNumber: _phoneController.text),
          );
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length != 10) {
      return 'Phone number must be 10 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Phone number should contain only digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Custom Paint Background Design
          CustomPaint(
            painter: LoginBackgroundPainter(),
            size: Size(screenWidth, screenHeight),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.08),

                      Center(
                        child: Image.asset(
                          Appconstants.applogo,
                          height: ResponsiveUtils.hp(30),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.005),

                      // Welcome Text
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Appcolors.kblackcolor,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Login to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Appcolors.kgreyColor.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.06),

                      // Phone Number Field
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Enter your phone number',
                        labelText: 'Phone Number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validatePhone,
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Submit Button with BLoC
            // Submit Button with BLoC
BlocConsumer<SendOtpBloc, SendOtpState>(
  listener: (context, state) {
    if (state is SendOtpSuccessState) {
      context.push(
        '/otppage',
        extra: {
          'phone': '+91 ${_phoneController.text}',
          'userId': state.executiveId,
        },
      );
    } else if (state is SendOtpErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  },
  builder: (context, state) {
    final isLoading = state is SendOtpLoadingState;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Appcolors.kprimarycolor,
          foregroundColor: Appcolors.kwhitecolor,
          elevation: 3,
          shadowColor: Appcolors.kprimarycolor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor:
              Appcolors.kprimarycolor.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Appcolors.kwhitecolor,
                  ),
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  },
),

                      SizedBox(height: screenHeight * 0.03),

                      // Terms & Conditions
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Appcolors.kgreyColor.withOpacity(0.7),
                          ),
                          children: const [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: Appcolors.kprimarycolor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Paint for Background Design
class LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top Right Circle
    final paint1 = Paint()
      ..color = Appcolors.kprimarycolor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.1),
      120,
      paint1,
    );

    // Top Right Small Circle
    final paint2 = Paint()
      ..color = Appcolors.kbordercolor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      60,
      paint2,
    );

    // Bottom Left Arc
    final paint3 = Paint()
      ..color = Appcolors.ksecondarycolor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.85,
      size.width * 0.5,
      size.height * 0.9,
    );
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint3);

    // Bottom Right Decorative Shape
    final paint4 = Paint()
      ..color = Appcolors.kprimarycolor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.85,
      size.width * 0.6,
      size.height,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint4);

    // Decorative dots
    final dotPaint = Paint()
      ..color = Appcolors.kbordercolor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.3), 8, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.5), 6, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), 10, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}