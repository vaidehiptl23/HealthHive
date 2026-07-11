import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'subscription_screen.dart';

class AddMemberScreen extends StatefulWidget {
  final String userEmail;

  const AddMemberScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<AddMemberScreen> createState() =>
      _AddMemberScreenState();
}

class _AddMemberScreenState
    extends State<AddMemberScreen> {

  final firstNameController =
  TextEditingController();
  final middleNameController =
  TextEditingController();
  final lastNameController =
  TextEditingController();
  final emailController =
  TextEditingController();
  final bloodGroupController =
  TextEditingController();
  final genderController =
  TextEditingController();
  final phoneController =
  TextEditingController();
  final dobController =
  TextEditingController();
  final heightController =
  TextEditingController();
  final weightController =
  TextEditingController();
  final addressController =
  TextEditingController();

  bool isSaving = false;

  void _saveMember() async {
    if (firstNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("First name is required"), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);

    final res = await ApiService.addFamilyMember({
      'first_name': firstNameController.text,
      'middle_name': middleNameController.text,
      'last_name': lastNameController.text,
      'email': emailController.text,
      'blood_group': bloodGroupController.text,
      'gender': genderController.text,
      'phone': phoneController.text,
      'dob': dobController.text,
      'height': heightController.text,
      'weight': weightController.text,
      'address': addressController.text,
    });

    setState(() => isSaving = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Family Member Added Successfully"), backgroundColor: AppColors.primary));
      Navigator.pop(context, true); // Pop with true to refresh list
    } else if (res['requiresUpgrade'] == true) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(
        onUpgradeSuccess: () {
          _saveMember(); // Automatically try saving again once payment succeeds!
        }
      )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Error adding member"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      bottomNavigationBar:
      CustomBottomNav(
        currentIndex: 4,
        userEmail: widget.userEmail,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20),
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
                    "Add Member",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ////////////////////////////////////////////////////////////
              /// FORM CARD
              ////////////////////////////////////////////////////////////

              Container(
                padding:
                const EdgeInsets.all(
                    20),
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius
                      .circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                          0.05),
                      blurRadius: 8,
                      offset:
                      const Offset(
                          0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [

                    buildLabel("First Name"),
                    buildField(firstNameController),

                    buildLabel("Middle Name"),
                    buildField(middleNameController),

                    buildLabel("Last Name"),
                    buildField(lastNameController),

                    buildLabel("Email ID"),
                    buildField(emailController),

                    const SizedBox(
                        height: 10),

                    /// Blood Group + Gender
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              buildLabel(
                                  "Blood Group"),
                              buildField(
                                  bloodGroupController),
                            ],
                          ),
                        ),
                        const SizedBox(
                            width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              buildLabel(
                                  "Gender"),
                              buildField(
                                  genderController),
                            ],
                          ),
                        ),
                      ],
                    ),

                    buildLabel("Phone No."),
                    buildField(phoneController),

                    buildLabel("DOB"),
                    buildField(dobController),

                    const SizedBox(
                        height: 10),

                    /// Height + Weight
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              buildLabel(
                                  "Height"),
                              buildField(
                                  heightController),
                            ],
                          ),
                        ),
                        const SizedBox(
                            width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              buildLabel(
                                  "Weight"),
                              buildField(
                                  weightController),
                            ],
                          ),
                        ),
                      ],
                    ),

                    buildLabel("Address"),
                    buildField(
                        addressController,
                        maxLines: 3),

                    const SizedBox(
                        height: 25),

                    ////////////////////////////////////////////////////////////
                    /// ADD MEMBER BUTTON
                    ////////////////////////////////////////////////////////////

                    SizedBox(
                      width:
                      double.infinity,
                      child:
                      ElevatedButton(
                        onPressed: isSaving ? null : _saveMember,
                        child: isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("Add Member"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// MODERN BACK BUTTON (No Navigation Change)
  //////////////////////////////////////////////////////////////

  Widget buildBackButton(
      BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: () {
        Navigator.pop(context);
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
  /// LABEL
  //////////////////////////////////////////////////////////////

  Widget buildLabel(String text) {
    return Padding(
      padding:
      const EdgeInsets.only(
          top: 16, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// INPUT FIELD
  //////////////////////////////////////////////////////////////

  Widget buildField(
      TextEditingController controller,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
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
        contentPadding:
        const EdgeInsets
            .symmetric(
            horizontal: 14,
            vertical: 12),
      ),
    );
  }
}
