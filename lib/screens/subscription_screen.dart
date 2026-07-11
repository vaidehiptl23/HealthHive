import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class SubscriptionScreen extends StatefulWidget {
  final VoidCallback onUpgradeSuccess;

  const SubscriptionScreen({super.key, required this.onUpgradeSuccess});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = 'plus';
  bool isUpgrading = false;

  void _upgrade() async {
    setState(() => isUpgrading = true);
    final res = await ApiService.upgradeSubscription(selectedPlan);
    setState(() => isUpgrading = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 Successfully upgraded to $selectedPlan!'), backgroundColor: AppColors.primary),
        );
        widget.onUpgradeSuccess();
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to upgrade'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hive Subscriptions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium, size: 80, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text("Unlock Your Hive", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Get more out of HealthHive by adding your whole family.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 40),

              _buildPlanCard("free", "Hive Free", "\$0 / mo", "1 Family Member Limit"),
              const SizedBox(height: 16),
              _buildPlanCard("plus", "Hive Plus", "\$4.99 / mo", "Up to 5 Family Members\nPriority Support"),
              const SizedBox(height: 16),
              _buildPlanCard("premium", "Hive Premium", "\$12.99 / mo", "Unlimited Family Members\nPriority Support\nAdvanced Syncing"),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isUpgrading ? null : _upgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isUpgrading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Upgrade Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String id, String title, String price, String features) {
    bool isSelected = selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black87)),
                      const Spacer(),
                      Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(features, style: const TextStyle(height: 1.4, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 28),
          ],
        ),
      ),
    );
  }
}
