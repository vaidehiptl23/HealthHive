import 'package:flutter/material.dart';
import 'login.dart';
import 'otp_verification.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController =
  TextEditingController();
  bool _isSending = false;

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    final email = emailController.text.trim();
    final error = await AuthService.sendOtp(email: email);
    if (!mounted) return;
    setState(() => _isSending = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent to your email!"), backgroundColor: AppColors.primary),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
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
                          const LoginScreen(),
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
                        Icons.lock_reset,
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
                      "Forgot Password",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  Center(
                    child: Text(
                      "Enter your registered email address.\nWe'll send a 4-digit OTP for verification.",
                      textAlign:
                      TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                          color: Colors
                              .black54),
                    ),
                  ),

                  const SizedBox(height: 35),

                  /// EMAIL LABEL
                  Text(
                    "Email Address",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),

                  const SizedBox(height: 10),

                  /// EMAIL FIELD
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller:
                      emailController,
                      decoration:
                      buildInputDecoration(
                          "Enter your email"),
                      validator: (value) {
                        if (value ==
                            null ||
                            value
                                .isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains("@")) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// SEND OTP BUTTON
                  SizedBox(
                    width:
                    double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendOtp,
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                        "Send OTP",
                        style: TextStyle(
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

  //////////////////////////////////////////////////////////////
  /// INPUT DECORATION
  //////////////////////////////////////////////////////////////

  InputDecoration buildInputDecoration(
      String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding:
      const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
