import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'recently_uploaded_docs.dart';
import 'add_member.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  final String userEmail;

  const AddFamilyMemberScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _subscriptionPlan = 'free';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    final res = await ApiService.getFamilyMembersResponse();
    if (mounted) {
      setState(() {
        _members = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _subscriptionPlan = res['subscriptionPlan'] ?? 'free';
        _isLoading = false;
      });
    }
  }

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
                    "Family Members",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: 35),

              ////////////////////////////////////////////////////////////
              /// MEMBERS LIST
              ////////////////////////////////////////////////////////////

              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _members.isEmpty
                        ? const Center(child: Text("No family members added yet.", style: TextStyle(color: Colors.black54)))
                        : ListView.builder(
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final m = _members[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: buildMemberCard(context, "${m['first_name']} ${m['last_name']}"),
                              );
                            },
                          ),
              ),

              ////////////////////////////////////////////////////////////
              /// ADD MEMBER BUTTON
              ////////////////////////////////////////////////////////////

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    int limit = 1;
                    if (_subscriptionPlan == 'plus') limit = 5;
                    if (_subscriptionPlan == 'premium') limit = 999;

                    if (_members.length >= limit) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubscriptionScreen(
                            onUpgradeSuccess: () {
                              _loadMembers();
                            },
                          ),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Plan limit reached. Upgrade to add more family members."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddMemberScreen(
                              userEmail: widget.userEmail,
                            ),
                      ),
                    ).then((didSave) {
                      if (didSave == true) _loadMembers();
                    });
                  },
                  child: const Text("+ Add Member"),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// MODERN BACK BUTTON (to Profile)
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
                  userEmail: widget.userEmail,
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
  /// MEMBER CARD (Premium Style)
  //////////////////////////////////////////////////////////////

  Widget buildMemberCard(
      BuildContext context,
      String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecentlyUploadedDocs(
                    userEmail: widget.userEmail,
                    filterFor: name,
                  ),
                ),
              );
            },
            child: Text(
              "View",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
