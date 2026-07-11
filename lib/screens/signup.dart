import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;
  bool isLoading = false;

  final TextEditingController nameController =
  TextEditingController();
  final TextEditingController emailController =
  TextEditingController();
  final TextEditingController phoneController =
  TextEditingController();
  final TextEditingController passwordController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                /// HEADER
                Text(
                  "Create Account",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Start managing your health smarter",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),

                const SizedBox(height: 40),

                /// CARD
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          /// FULL NAME
                          buildInputField(
                            controller:
                            nameController,
                            hint: "Full Name",
                            icon:
                            Icons.person_outline,
                            maxLength: 50,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return "Full name required";
                              }
                              if (!RegExp(
                                  r'^[a-zA-Z\s]+$')
                                  .hasMatch(value)) {
                                return "Only letters allowed";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          /// EMAIL
                          buildInputField(
                            controller:
                            emailController,
                            hint: "Email",
                            icon:
                            Icons.email_outlined,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return "Email required";
                              }
                              if (!value.endsWith(
                                  "@gmail.com")) {
                                return "Must end with @gmail.com";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          /// PHONE
                          buildInputField(
                            controller:
                            phoneController,
                            hint: "Phone Number",
                            icon:
                            Icons.phone_outlined,
                            keyboardType:
                            TextInputType.number,
                            maxLength: 10,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return "Phone required";
                              }
                              if (!RegExp(
                                  r'^[0-9]+$')
                                  .hasMatch(value)) {
                                return "Numbers only";
                              }
                              if (value.length != 10) {
                                return "Must be 10 digits";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          /// PASSWORD
                          buildInputField(
                            controller:
                            passwordController,
                            hint: "Password",
                            icon:
                            Icons.lock_outline,
                            obscure:
                            !isPasswordVisible,
                            suffix: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons
                                    .visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible =
                                  !isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return "Password required";
                              }
                              if (!RegExp(
                                  r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&]).+$')
                                  .hasMatch(value)) {
                                return "Must contain letter, number & symbol";
                              }
                              if (value.length < 6) {
                                return "Minimum 6 characters";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 25),

                          /// CREATE ACCOUNT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => isLoading = true);

                                  final error = await AuthService.register(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text,
                                    phone: phoneController.text.trim(),
                                  );

                                  if (!mounted) return;
                                  setState(() => isLoading = false);

                                  if (error == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Account created! Please login.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text("Create Account"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// LOGIN LINK
                Center(
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      const Text(
                          "Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                              context);
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w600,
                            color:
                            AppColors.primary,
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
  /// REUSABLE INPUT FIELD
  //////////////////////////////////////////////////////////////

  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType =
        TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
        Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        counterText: "",
      ),
    );
  }
}
