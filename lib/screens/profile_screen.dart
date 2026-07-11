import 'package:flutter/material.dart';
import 'package:healthhive/screens/reset_password.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'login.dart';
import 'add_family_member.dart';
import 'emergency_details.dart';
import 'update_profile.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _realName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await ApiService.getProfile();
    if (res['success'] == true && res['data'] != null) {
      if (mounted) setState(() => _realName = res['data']['user']['name']);
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = _realName ?? widget.userEmail.split('@')[0];

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
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              ////////////////////////////////////////////////////////////
              /// UPDATED HEADER (Modern Back Button)
              ////////////////////////////////////////////////////////////
              Row(
                children: [
                  buildBackButton(context),
                  const SizedBox(width: 8),
                  Text(
                    "Profile",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ////////////////////////////////////////////////////////////
              /// USER CARD
              ////////////////////////////////////////////////////////////
              Container(
                padding:
                const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [

                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                      AppColors.primary
                          .withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        color:
                        AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            userName,
                            style: Theme.of(
                                context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(
                              height: 4),
                          Text(
                            widget.userEmail,
                            style: Theme.of(
                                context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color:
                              Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color:
                        AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UpdateProfileScreen(
                                  userEmail:
                                  widget.userEmail,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              ////////////////////////////////////////////////////////////
              /// OPTIONS
              ////////////////////////////////////////////////////////////

              buildOptionCard(
                context,
                icon:
                Icons.lock_outline,
                title:
                "Change Password",
                screen:
                ChangePasswordScreen(
                    userEmail:
                    widget.userEmail),
              ),

              buildOptionCard(
                context,
                icon:
                Icons.group_outlined,
                title:
                "Add Family Member",
                screen:
                AddFamilyMemberScreen(
                    userEmail:
                    widget.userEmail),
              ),

              buildOptionCard(
                context,
                icon: Icons
                    .local_hospital_outlined,
                title:
                "Emergency Details",
                screen:
                EmergencyDetails(
                    userEmail:
                    widget.userEmail),
              ),

              buildLogoutCard(context),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// MODERN BACK BUTTON (Same Across App)
  //////////////////////////////////////////////////////////////

  Widget buildBackButton(BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(
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
          BorderRadius.circular(12),
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
  /// OPTION CARD
  //////////////////////////////////////////////////////////////

  Widget buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Widget screen,
      }) {
    return Container(
      margin:
      const EdgeInsets.only(
          bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 6,
          )
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyLarge,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => screen),
          );
        },
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// LOGOUT CARD
  //////////////////////////////////////////////////////////////

  Widget buildLogoutCard(
      BuildContext context) {
    return Container(
      margin:
      const EdgeInsets.only(
          top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 6,
          )
        ],
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: Colors.redAccent,
        ),
        title: const Text("Log Out"),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  backgroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(16),
                  ),
                  title: const Text(
                    "Confirm Logout",
                    style: TextStyle(
                        fontWeight:
                        FontWeight.bold),
                  ),
                  content: const Text(
                      "Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                              context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            color: Colors
                                .black54),
                      ),
                    ),
                    ElevatedButton(
                      style:
                       ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator
                            .pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child:
                      const Text("Logout"),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}
