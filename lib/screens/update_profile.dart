import 'package:flutter/material.dart';
import 'package:healthhive/screens/profile_screen.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String userEmail;

  const UpdateProfileScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<UpdateProfileScreen> createState() =>
      _UpdateProfileScreenState();
}

class _UpdateProfileScreenState
    extends State<UpdateProfileScreen> {

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final genderController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.userEmail;
    _loadProfile();
  }

  void _loadProfile() async {
    final res = await ApiService.getProfile();
    if (res['success'] == true && res['data'] != null) {
      final user = res['data']['user'];
      firstNameController.text = user['first_name'] ?? widget.userEmail.split('@')[0];
      middleNameController.text = user['middle_name'] ?? '';
      lastNameController.text = user['last_name'] ?? '';
      bloodGroupController.text = user['blood_group'] ?? '';
      genderController.text = user['gender'] ?? '';
      phoneController.text = user['phone'] ?? '';
      dobController.text = user['dob'] ?? '';
      heightController.text = user['height'] ?? '';
      weightController.text = user['weight'] ?? '';
      addressController.text = user['address'] ?? '';
    } else {
      firstNameController.text = widget.userEmail.split('@')[0];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    final res = await ApiService.updateProfile({
      'first_name': firstNameController.text,
      'middle_name': middleNameController.text,
      'last_name': lastNameController.text,
      'blood_group': bloodGroupController.text,
      'gender': genderController.text,
      'phone': phoneController.text,
      'dob': dobController.text,
      'height': heightController.text,
      'weight': weightController.text,
      'address': addressController.text,
    });
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully"), backgroundColor: AppColors.primary));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(userEmail: widget.userEmail)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar:
      CustomBottomNav(
        currentIndex: 4,
        userEmail: widget.userEmail,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              ////////////////////////////////////////////////////////////
              /// HEADER (Modern Back Arrow)
              ////////////////////////////////////////////////////////////
              Row(
                children: [
                  buildBackButton(context),
                  const SizedBox(width: 8),
                  Text(
                    "Update Profile",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ////////////////////////////////////////////////////////////
              /// PROFILE FORM CARD
              ////////////////////////////////////////////////////////////
              Container(
                padding:
                const EdgeInsets.all(20),
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
                child: _isLoading 
                  ? const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
                  : Column(
                  children: [

                    buildField(
                        firstNameController,
                        "First Name"),

                    buildField(
                        middleNameController,
                        "Middle Name"),

                    buildField(
                        lastNameController,
                        "Last Name"),

                    buildField(
                        emailController,
                        "Email ID"),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                              bloodGroupController,
                              "Blood Group"),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: buildField(
                              genderController,
                              "Gender"),
                        ),
                      ],
                    ),

                    buildField(
                        phoneController,
                        "Phone No."),

                    buildField(
                        dobController,
                        "Date of Birth"),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                              heightController,
                              "Height"),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: buildField(
                              weightController,
                              "Weight"),
                        ),
                      ],
                    ),

                    buildField(
                      addressController,
                      "Address",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    ////////////////////////////////////////////////////
                    /// SAVE BUTTON
                    ////////////////////////////////////////////////////
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// MODERN BACK BUTTON
  //////////////////////////////////////////////////////////////

  Widget buildBackButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              userEmail: widget.userEmail,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
  /// INPUT FIELD (Modern)
  //////////////////////////////////////////////////////////////

  Widget buildField(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
      }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor:
          AppColors.background,
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide:
            BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
