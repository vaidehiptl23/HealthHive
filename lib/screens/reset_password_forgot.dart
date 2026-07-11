import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'login.dart';

class ResetPasswordForgotScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordForgotScreen({super.key, required this.resetToken});

  @override
  State<ResetPasswordForgotScreen> createState() => _ResetPasswordForgotScreenState();
}

class _ResetPasswordForgotScreenState extends State<ResetPasswordForgotScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  bool showNew = false;
  bool showConfirm = false;
  bool _isSaving = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final error = await AuthService.resetPassword(
      resetToken: widget.resetToken,
      newPassword: newController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset successfully! Please login."),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    /// ICON
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_open,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// TITLE
                    Center(
                      child: Text(
                        "Reset Password",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// DESCRIPTION
                    Center(
                      child: Text(
                        "Create a strong new password for your account.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// NEW PASSWORD
                    _buildPasswordField(
                      controller: newController,
                      hint: "New Password",
                      isVisible: showNew,
                      toggle: () => setState(() => showNew = !showNew),
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRM PASSWORD
                    _buildPasswordField(
                      controller: confirmController,
                      hint: "Confirm Password",
                      isVisible: showConfirm,
                      toggle: () => setState(() => showConfirm = !showConfirm),
                    ),

                    const SizedBox(height: 35),

                    /// RESET BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _resetPassword,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                          "Reset Password",
                          style: TextStyle(fontWeight: FontWeight.w600),
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
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback toggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$hint is required";
        }
        if (hint == "New Password") {
          if (value.length < 6) {
            return "Minimum 6 characters required";
          }
          if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&]).+$').hasMatch(value)) {
            return "Must contain letter, number & special character";
          }
        }
        if (hint == "Confirm Password") {
          if (value != newController.text) {
            return "Passwords do not match";
          }
        }
        return null;
      },
    );
  }
}
