import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/reminder_data.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';

class UpcomingRemindersScreen extends StatefulWidget {
  final String userEmail;
  const UpcomingRemindersScreen({super.key, required this.userEmail});

  @override
  State<UpcomingRemindersScreen> createState() => _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  bool _loading = true;

  List<Map<String, String>> appointments = [];
  List<Map<String, String>> medicines = [];
  List<Map<String, String>> tests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appointmentList = await ApiService.getAppointmentReminders();
    final medicineList = await ApiService.getMedicineReminders();
    final testList = await ApiService.getTestReminders();

    final appts = <Map<String, String>>[];
    final meds = <Map<String, String>>[];
    final tsts = <Map<String, String>>[];

    for (final a in appointmentList) {
      appts.add({
        'title': a['purpose'] as String? ?? 'Doctor Appointment',
        'subtitle': '${a['date'] ?? ''}${a['time'] != null ? ' • ${a['time']}' : ''}',
      });
    }
    for (final m in medicineList) {
      meds.add({
        'title': m['name'] as String? ?? '',
        'subtitle': m['meal'] as String? ?? 'No Meal Dependency',
      });
    }
    for (final t in testList) {
      tsts.add({
        'title': t['name'] as String? ?? '',
        'subtitle': t['meal'] as String? ?? 'No Meal Dependency',
      });
    }

    // Also sync to ReminderData so home screen stays in sync
    ReminderData.appointments
      ..clear()
      ..addAll(appts);
    ReminderData.medicines
      ..clear()
      ..addAll(meds);
    ReminderData.tests
      ..clear()
      ..addAll(tsts);

    if (mounted) {
      setState(() {
        appointments = appts;
        medicines = meds;
        tests = tsts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool empty = appointments.isEmpty && medicines.isEmpty && tests.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomBottomNav(currentIndex: 0, userEmail: widget.userEmail),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _backButton(),
                const SizedBox(width: 8),
                Text("Upcoming Reminders",
                    style: Theme.of(context).textTheme.headlineSmall),
              ]),
              const SizedBox(height: 30),

              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (empty)
                Expanded(
                  child: Center(
                    child: Text("No reminders added yet.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54)),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      if (appointments.isNotEmpty) ...[
                        _sectionTitle(context, "Appointments", Colors.blue),
                        const SizedBox(height: 12),
                        ...appointments.map((item) => _card(
                              title: item['title']!,
                              subtitle: item['subtitle']!,
                              color: Colors.blue,
                              icon: Icons.calendar_today,
                            )),
                        const SizedBox(height: 24),
                      ],
                      if (medicines.isNotEmpty) ...[
                        _sectionTitle(context, "Medicines", Colors.orange),
                        const SizedBox(height: 12),
                        ...medicines.map((item) => _card(
                              title: item['title']!,
                              subtitle: item['subtitle']!,
                              color: Colors.orange,
                              icon: Icons.medication,
                            )),
                        const SizedBox(height: 24),
                      ],
                      if (tests.isNotEmpty) ...[
                        _sectionTitle(context, "Tests", Colors.deepPurple),
                        const SizedBox(height: 12),
                        ...tests.map((item) => _card(
                              title: item['title']!,
                              subtitle: item['subtitle']!,
                              color: Colors.deepPurple,
                              icon: Icons.science,
                            )),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, Color color) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600, color: color)),
    ]);
  }

  Widget _card({required String title, required String subtitle, required Color color, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80), width: 1.2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _backButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HomeScreen(userEmail: widget.userEmail))),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.arrow_back, color: AppColors.primary),
      ),
    );
  }
}
