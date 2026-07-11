import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/upload_new_docs.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/add_appointment_reminder.dart';
import '../screens/add_medicine_reminder.dart';
import '../screens/add_test_reminder.dart';
import '../utils/colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final String userEmail;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.userEmail,
  });

  void _showReminderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "What would you like to add?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text("Appointment Reminder", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => AddAppointmentReminderScreen(userEmail: userEmail)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication, color: Colors.orange),
                  title: const Text("Medicine Reminder", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => AddMedicineReminderScreen(userEmail: userEmail)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.science, color: Colors.deepPurple),
                  title: const Text("Test Reminder", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => AddTestReminderScreen(userEmail: userEmail)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 3) {
      _showReminderOptions(context);
      return;
    }

    Widget nextScreen;

    switch (index) {
      case 0:
        nextScreen = HomeScreen(userEmail: userEmail);
        break;
      case 1:
        nextScreen = UploadNewDocsScreen(userEmail: userEmail);
        break;
      case 2:
        nextScreen = AIChatScreen(userEmail: userEmail);
        break;
      case 4:
        nextScreen = ProfileScreen(userEmail: userEmail);
        break;
      default:
        nextScreen = HomeScreen(userEmail: userEmail);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.whiteCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_outlined),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "",
        ),
      ],
    );
  }
}
