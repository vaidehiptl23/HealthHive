import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/reminder_data.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class AddAppointmentReminderScreen extends StatefulWidget {
  final String userEmail;
  const AddAppointmentReminderScreen({super.key, required this.userEmail});

  @override
  State<AddAppointmentReminderScreen> createState() =>
      _AddAppointmentReminderScreenState();
}

class _AddAppointmentReminderScreenState
    extends State<AddAppointmentReminderScreen> {
  final placeController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final purposeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  _buildBackButton(),
                  const SizedBox(width: 8),
                  Text("Appointment Reminder",
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(placeController, "Place"),
                    _buildField(dateController, "Date"),
                    _buildTimeField(timeController, "Time"),
                    _buildField(purposeController, "Purpose"),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (dateController.text.isNotEmpty) {
                            final purpose = purposeController.text.isEmpty
                                ? "Doctor Appointment"
                                : purposeController.text;
                            ReminderData.appointments.add({
                              "title": purpose,
                              "subtitle": "${dateController.text}${timeController.text.isNotEmpty ? ' • ${timeController.text}' : ''}",
                            });
                            await ApiService.saveAppointmentReminder(
                              place: placeController.text.isNotEmpty ? placeController.text : null,
                              date: dateController.text,
                              time: timeController.text.isNotEmpty ? timeController.text : null,
                              purpose: purposeController.text.isNotEmpty ? purposeController.text : null,
                            );
                          }
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen(userEmail: widget.userEmail)),
                            (route) => false,
                          );
                        },
                        child: const Text("Add Appointment"),
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

  Widget _buildBackButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userEmail: widget.userEmail)),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.primary),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null && mounted) {
            setState(() {
              controller.text = picked.format(context);
            });
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
      ),
    );
  }
}
