import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class EmergencyDetails extends StatefulWidget {
  final String userEmail;

  const EmergencyDetails({
    super.key,
    required this.userEmail,
  });

  @override
  State<EmergencyDetails> createState() =>
      _EmergencyDetailsState();
}

class _EmergencyDetailsState
    extends State<EmergencyDetails> {

  final TextEditingController contactNameController =
  TextEditingController();
  final TextEditingController phoneController =
  TextEditingController();
  final TextEditingController bloodGroupController =
  TextEditingController();
  final TextEditingController allergiesController =
  TextEditingController();
  final TextEditingController conditionsController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  List<dynamic> _familyMembers = [];
  String _selectedPersonId = 'self';
  Map<String, dynamic>? _myEmergencyData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final selfRes = await ApiService.getEmergencyDetails();
    if (selfRes['success'] == true) {
      _myEmergencyData = selfRes['data'];
    }

    _familyMembers = await ApiService.getFamilyMembers();

    _populateFields();
    if (mounted) setState(() => _isLoading = false);
  }

  void _populateFields() {
    Map<String, dynamic>? d;

    if (_selectedPersonId == 'self') {
      d = _myEmergencyData;
    } else {
      final idInt = int.tryParse(_selectedPersonId);
      final match = _familyMembers.where((f) => f['id'] == idInt).toList();
      if (match.isNotEmpty) d = match.first;
    }

    contactNameController.text = d?['emergency_contact_name'] ?? '';
    phoneController.text = d?['emergency_contact_phone'] ?? '';
    bloodGroupController.text = d?['emergency_blood_group'] ?? '';
    allergiesController.text = d?['allergies'] ?? '';
    conditionsController.text = d?['existing_conditions'] ?? '';
  }

  void _onPersonSelected(String? newId) {
    if (newId == null || newId == _selectedPersonId) return;
    setState(() {
      _selectedPersonId = newId;
      _populateFields();
    });
  }

  Future<void> _saveEmergencyDetails() async {
    setState(() => _isSaving = true);
    
    final payload = {
      'emergency_contact_name': contactNameController.text,
      'emergency_contact_phone': phoneController.text,
      'emergency_blood_group': bloodGroupController.text,
      'allergies': allergiesController.text,
      'existing_conditions': conditionsController.text,
    };

    dynamic res;
    if (_selectedPersonId == 'self') {
      res = await ApiService.updateEmergencyDetails(payload);
      if (res['success'] == true) _myEmergencyData = payload; // Update local cache
    } else {
      res = await ApiService.updateFamilyEmergencyDetails(int.parse(_selectedPersonId), payload);
      // Update local family array cache
      if (res['success'] == true) {
        final idInt = int.tryParse(_selectedPersonId);
        final index = _familyMembers.indexWhere((f) => f['id'] == idInt);
        if (index != -1) {
          _familyMembers[index].addAll(payload);
        }
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency details saved successfully"), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save emergency details"), backgroundColor: Colors.red),
      );
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: CustomBottomNav(
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
              /// HEADER
              ////////////////////////////////////////////////////////////

              Row(
                children: [
                  buildBackButton(context),
                  const SizedBox(width: 8),
                  Text(
                    "Emergency Details",
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
                const EdgeInsets.all(20),
                decoration:
                BoxDecoration(
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
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  : Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    buildLabel("Select Person"),
                    DropdownButtonFormField<String>(
                      value: _selectedPersonId,
                      onChanged: _onPersonSelected,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'self', child: Text("Myself")),
                        ..._familyMembers.map((f) => DropdownMenuItem(
                              value: f['id'].toString(),
                              child: Text("${f['first_name']} ${f['last_name']}"),
                            )).toList(),
                      ],
                    ),
                    const SizedBox(height: 10),

                    buildLabel(
                        "Emergency Contact Name"),
                    buildField(
                        contactNameController),

                    buildLabel(
                        "Emergency Contact Phone"),
                    buildField(phoneController,
                        keyboard:
                        TextInputType
                            .phone),

                    buildLabel(
                        "Blood Group"),
                    buildField(
                        bloodGroupController),

                    buildLabel("Allergies"),
                    buildField(
                        allergiesController,
                        maxLines: 2),

                    buildLabel(
                        "Existing Conditions"),
                    buildField(
                        conditionsController,
                        maxLines: 2),

                    const SizedBox(
                        height: 25),

                    ////////////////////////////////////////////////////////////
                    /// SAVE BUTTON
                    ////////////////////////////////////////////////////////////

                    SizedBox(
                      width:
                      double.infinity,
                      child:
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveEmergencyDetails,
                        child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save"),
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
  /// MODERN BACK BUTTON (Navigate to Profile)
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
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType keyboard =
            TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
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
