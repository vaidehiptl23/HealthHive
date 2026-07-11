import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/reminder_data.dart';
import 'home_screen.dart';

class AddTestReminderScreen extends StatefulWidget {
  final String userEmail;
  const AddTestReminderScreen({super.key, required this.userEmail});

  @override
  State<AddTestReminderScreen> createState() => _AddTestReminderScreenState();
}

class _AddTestReminderScreenState extends State<AddTestReminderScreen> {
  final List<Map<String, dynamic>> tests = [];
  final List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final List<String> mealOptions = ["After Meal", "Empty Stomach", "No Dependency"];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addField();
  }

  void _addField() {
    tests.add({
      "name": TextEditingController(),
      "meal": null,
      "morning": false,
      "afternoon": false,
      "night": false,
      "morningTime": null,
      "afternoonTime": null,
      "nightTime": null,
      "repeatDays": <String>[],
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

  Future<void> _save() async {
    setState(() => _saving = true);
    const dayMapping = {
      "Mon": DateTime.monday,
      "Tue": DateTime.tuesday,
      "Wed": DateTime.wednesday,
      "Thu": DateTime.thursday,
      "Fri": DateTime.friday,
      "Sat": DateTime.saturday,
      "Sun": DateTime.sunday,
    };

    for (var test in tests) {
      final name = (test["name"] as TextEditingController).text.trim();
      if (name.isEmpty) continue;
      final meal = test["meal"] as String?;
      final morningTime = test["morningTime"] != null ? _fmt(test["morningTime"] as TimeOfDay) : null;
      final afternoonTime = test["afternoonTime"] != null ? _fmt(test["afternoonTime"] as TimeOfDay) : null;
      final nightTime = test["nightTime"] != null ? _fmt(test["nightTime"] as TimeOfDay) : null;
      ReminderData.tests.add({"title": name, "subtitle": meal ?? "No Meal Dependency"});
      
      await ApiService.saveTestReminder(
        name: name,
        meal: meal,
        morning: test["morning"] as bool,
        morningTime: morningTime,
        afternoon: test["afternoon"] as bool,
        afternoonTime: afternoonTime,
        night: test["night"] as bool,
        nightTime: nightTime,
        repeatDays: List<String>.from(test["repeatDays"] as List),
      );

      // Helper function to schedule local notifications
      Future<void> scheduleTestNotification(TimeOfDay? time, String periodLabel) async {
        if (time == null) return;
        final id = Random().nextInt(100000);
        final title = "🧪 Test Reminder";
        final body = "It's time for your health test: $name ($periodLabel)";
        
        final days = List<String>.from(test["repeatDays"] as List);
        if (days.isEmpty) {
          await NotificationService.scheduleDailyNotification(
            id: id,
            title: title,
            body: body,
            time: time,
          );
        } else {
          for (var day in days) {
            final weekday = dayMapping[day];
            if (weekday != null) {
              await NotificationService.scheduleWeeklyNotification(
                id: Random().nextInt(100000),
                title: title,
                body: body,
                time: time,
                weekday: weekday,
              );
            }
          }
        }
      }

      if (test["morning"] == true) {
        await scheduleTestNotification(test["morningTime"] as TimeOfDay?, "Morning");
      }
      if (test["afternoon"] == true) {
        await scheduleTestNotification(test["afternoonTime"] as TimeOfDay?, "Afternoon");
      }
      if (test["night"] == true) {
        await scheduleTestNotification(test["nightTime"] as TimeOfDay?, "Night");
      }
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(userEmail: widget.userEmail)),
      (route) => false,
    );
  }

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
              Row(children: [
                _backButton(),
                const SizedBox(width: 8),
                Text("Test Reminder", style: Theme.of(context).textTheme.headlineSmall),
              ]),
              const SizedBox(height: 24),
              ...tests.asMap().entries.map((entry) {
                final i = entry.key;
                final test = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple, width: 1.2),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (tests.length > 1)
                      Align(
                        alignment: Alignment.topRight,
                        child: Text("Test ${i + 1}", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                      ),
                    _field(test["name"], "Test Name"),
                    _dropdown(test, mealOptions),
                    const SizedBox(height: 8),
                    const Text("Time", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _timeRow(tests, i, "morning", "Morning"),
                    _timeRow(tests, i, "afternoon", "Afternoon"),
                    _timeRow(tests, i, "night", "Night"),
                    const SizedBox(height: 12),
                    const Text("Repeat Days", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _repeatChips(test),
                  ]),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _addField()),
                icon: const Icon(Icons.add, color: Colors.deepPurple),
                label: const Text("Add Another Test", style: TextStyle(color: Colors.deepPurple)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Save Tests", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder())),
    );
  }

  Widget _dropdown(Map<String, dynamic> item, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: item["meal"] as String?,
        decoration: const InputDecoration(labelText: "Meal Dependency", border: OutlineInputBorder()),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) => setState(() => item["meal"] = v),
      ),
    );
  }

  Widget _timeRow(List<Map<String, dynamic>> list, int index, String key, String label) {
    final emojis = {"morning": "☀️", "afternoon": "🌤", "night": "🌙"};
    final selected = list[index][key] as bool;
    final time = list[index]["${key}Time"] as TimeOfDay?;
    return Row(children: [
      Checkbox(
        value: selected,
        activeColor: Colors.deepPurple,
        onChanged: (val) async {
          setState(() => list[index][key] = val);
          if (val == true) {
            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (picked != null && mounted) setState(() => list[index]["${key}Time"] = picked);
          }
        },
      ),
      Text(emojis[key] ?? "", style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 6),
      Text(label),
      if (selected && time != null) ...[
        const SizedBox(width: 10),
        Text(time.format(context), style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    ]);
  }

  Widget _repeatChips(Map<String, dynamic> item) {
    return Wrap(
      spacing: 8, runSpacing: 4,
      children: weekDays.map((day) {
        final selected = (item["repeatDays"] as List<String>).contains(day);
        return ChoiceChip(
          label: Text(day), selected: selected,
          selectedColor: Colors.deepPurple.shade100,
          onSelected: (val) => setState(() {
            if (val) { (item["repeatDays"] as List<String>).add(day); }
            else { (item["repeatDays"] as List<String>).remove(day); }
          }),
        );
      }).toList(),
    );
  }

  Widget _backButton() {
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.arrow_back, color: AppColors.primary),
      ),
    );
  }
}