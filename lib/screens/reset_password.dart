import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import 'profile_screen.dart';
import 'forgot_password.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userEmail;

  const ChangePasswordScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController currentController =
  TextEditingController();
  final TextEditingController newController =
  TextEditingController();
  final TextEditingController confirmController =
  TextEditingController();

  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: CustomBottomNav(
        currentIndex: 4,
        userEmail: widget.userEmail,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                ////////////////////////////////////////////////////////////
                /// HEADER
                ////////////////////////////////////////////////////////////
                Row(
                  children: [
                    buildBackButton(context),
                    const SizedBox(width: 8),
                    Text(
                      "Change Password",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                ////////////////////////////////////////////////////////////
                /// CARD CONTAINER
                ////////////////////////////////////////////////////////////
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.05),
                        blurRadius: 8,
                        offset:
                        const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      buildPasswordField(
                        controller:
                        currentController,
                        hint:
                        "Current Password",
                        isVisible:
                        showCurrent,
                        toggle: () {
                          setState(() {
                            showCurrent =
                            !showCurrent;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      buildPasswordField(
                        controller:
                        newController,
                        hint: "New Password",
                        isVisible: showNew,
                        toggle: () {
                          setState(() {
                            showNew = !showNew;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      buildPasswordField(
                        controller:
                        confirmController,
                        hint:
                        "Re-enter New Password",
                        isVisible:
                        showConfirm,
                        toggle: () {
                          setState(() {
                            showConfirm =
                            !showConfirm;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey
                                .currentState!
                                .validate()) {
                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Password changed successfully"),
                                ),
                              );
                            }
                          },
                          child:
                          const Text(
                              "Change Password"),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// MODERN BACK BUTTON (to Profile Screen)
  //////////////////////////////////////////////////////////////

  Widget buildBackButton(
      BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProfileScreen(
                  userEmail:
                  widget.userEmail,
                ),
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
              12),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.primary,
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// PASSWORD FIELD
  //////////////////////////////////////////////////////////////

  Widget buildPasswordField({
    required TextEditingController
    controller,
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
        fillColor:
        AppColors.background,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
              14),
          borderSide:
          BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility
                : Icons
                .visibility_off,
          ),
          onPressed: toggle,
        ),
      ),
      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return "$hint is required";
        }

        if (hint ==
            "New Password") {
          if (!RegExp(
              r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&]).+$')
              .hasMatch(value)) {
            return "Must contain letter, number & special character";
          }
          if (value.length < 6) {
            return "Minimum 6 characters required";
          }
        }

        if (hint ==
            "Re-enter New Password") {
          if (value !=
              newController.text) {
            return "Passwords do not match";
          }
        }

        return null;
      },
    );
  }
}
