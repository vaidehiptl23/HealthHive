import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'forgot_password.dart';
import 'reset_password_forgot.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;

  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState
    extends State<OTPVerificationScreen> {

  int secondsRemaining = 300; // 5 minutes
  Timer? timer;
  bool _isVerifying = false;
  bool _isResending = false;

  final List<TextEditingController> controllers =
  List.generate(4, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (secondsRemaining > 0) {
          setState(() {
            secondsRemaining--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> verifyOTP() async {
    String otp = controllers.map((c) => c.text).join();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 4-digit OTP")),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final result = await AuthService.verifyOtp(email: widget.email, otp: otp);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP verified!"), backgroundColor: AppColors.primary),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordForgotScreen(
            resetToken: result['resetToken'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Invalid OTP'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    final error = await AuthService.sendOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (error == null) {
      setState(() => secondsRemaining = 300);
      startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP resent!"), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget buildOTPBox(int index) {
    return SizedBox(
      width: 55,
      height: 55,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              FocusScope.of(context)
                  .requestFocus(
                  focusNodes[index + 1]);
            } else {
              focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              FocusScope.of(context)
                  .requestFocus(
                  focusNodes[index - 1]);
            }
          }
        },
      ),
    );
  }

  String get _timerText {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  /// BACK BUTTON
                  InkWell(
                    borderRadius:
                    BorderRadius.circular(
                        12),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding:
                      const EdgeInsets.all(
                          8),
                      decoration:
                      BoxDecoration(
                        color:
                        AppColors.background,
                        borderRadius:
                        BorderRadius.circular(
                            12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color:
                        AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// ICON
                  Center(
                    child: Container(
                      padding:
                      const EdgeInsets.all(
                          20),
                      decoration:
                      BoxDecoration(
                        color: AppColors
                            .primary
                            .withOpacity(
                            0.1),
                        shape:
                        BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 50,
                        color:
                        AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TITLE
                  Center(
                    child: Text(
                      "Verification Code",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  Center(
                    child: Text(
                      "Enter the 4-digit code sent to\n${widget.email}",
                      textAlign:
                      TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                          color:
                          Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 35),

                  /// OTP BOXES
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children:
                    List.generate(
                      4,
                          (index) =>
                          buildOTPBox(
                              index),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// TIMER
                  Center(
                    child: Text(
                      secondsRemaining > 0
                          ? _timerText
                          : "Code expired",
                      style: TextStyle(
                        color:
                        secondsRemaining > 0
                            ? AppColors
                            .primary
                            : Colors.red,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// VERIFY BUTTON
                  SizedBox(
                    width:
                    double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : verifyOTP,
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                        "Verify",
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// RESEND
                  Center(
                    child: TextButton(
                      onPressed:
                      secondsRemaining == 0 && !_isResending
                          ? _resendOtp
                          : null,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                        "Resend Code",
                        style: TextStyle(
                          color:
                          secondsRemaining ==
                              0
                              ? AppColors
                              .primary
                              : Colors.grey,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
