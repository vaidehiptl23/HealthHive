import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';

class DietPlannerScreen extends StatefulWidget {
  final String userEmail;
  const DietPlannerScreen({super.key, required this.userEmail});

  @override
  State<DietPlannerScreen> createState() => _DietPlannerScreenState();
}

class _DietPlannerScreenState extends State<DietPlannerScreen> {
  String _dietPlan = "";
  bool _loading = true;
  String _dietPreference = "Vegetarian";

  @override
  void initState() {
    super.initState();
    _loadDietPlan();
  }

  Future<void> _loadDietPlan() async {
    setState(() => _loading = true);
    final res = await ApiService.getDietPlan(dietType: _dietPreference);
    if (mounted) {
      setState(() {
        _dietPlan = res['dietPlan'] ?? 'Could not compile a wellness plan.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomBottomNav(currentIndex: 0, userEmail: widget.userEmail),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadDietPlan,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text("Regenerate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6)
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Nutrition Planner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        SizedBox(height: 2),
                        Text('Condition-Specific Diet Guide', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                ],
              ),

              const SizedBox(height: 16),

              // Diet Preference Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dietPreferenceChip("🥦 Veg", "Vegetarian"),
                  _dietPreferenceChip("🍗 Non-Veg", "Non-Vegetarian"),
                  _dietPreferenceChip("🌱 Vegan", "Vegan"),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: _loading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Compiling your diet profile...", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView(
                            children: [
                              ..._dietPlan.split('\n').map((line) {
                                final trimmed = line.trim();
                                if (trimmed.startsWith('###')) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 14, bottom: 6),
                                    child: Text(
                                      trimmed.replaceAll('###', '').trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                    ),
                                  );
                                } else if (trimmed.startsWith('##')) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 18, bottom: 8),
                                    child: Text(
                                      trimmed.replaceAll('##', '').trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                    ),
                                  );
                                } else if (trimmed.startsWith('#')) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                                    child: Text(
                                      trimmed.replaceAll('#', '').trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                    ),
                                  );
                                } else if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                                        Expanded(
                                          child: Text(
                                            trimmed.substring(1).trim().replaceAll('**', ''),
                                            style: const TextStyle(fontSize: 13, height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (trimmed.isEmpty) {
                                  return const SizedBox(height: 10);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    trimmed.replaceAll('**', ''),
                                    style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                                  ),
                                );
                              }),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dietPreferenceChip(String label, String value) {
    final isSelected = _dietPreference == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: isSelected ? AppColors.primary : Colors.black12),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _dietPreference = value;
          });
          _loadDietPlan();
        }
      },
    );
  }
}
