import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../models/reminder_data.dart';
import 'home_screen.dart';

class AddMedicineReminderScreen extends StatefulWidget {
  final String userEmail;
  const AddMedicineReminderScreen({super.key, required this.userEmail});

  @override
  State<AddMedicineReminderScreen> createState() => _AddMedicineReminderScreenState();
}

class _AddMedicineReminderScreenState extends State<AddMedicineReminderScreen> {
  final List<Map<String, dynamic>> medicines = [];
  final List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final List<String> mealOptions = ["After Meal", "With Meal", "Empty Stomach", "No Dependency"];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addField();
  }

  void _addField() {
    medicines.add({
      "name": TextEditingController(),
      "dose": TextEditingController(),
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
    for (var med in medicines) {
      final name = (med["name"] as TextEditingController).text.trim();
      if (name.isEmpty) continue;
      final dose = (med["dose"] as TextEditingController).text.trim();
      final meal = med["meal"] as String?;
      final morningTime = med["morningTime"] != null ? _fmt(med["morningTime"] as TimeOfDay) : null;
      final afternoonTime = med["afternoonTime"] != null ? _fmt(med["afternoonTime"] as TimeOfDay) : null;
      final nightTime = med["nightTime"] != null ? _fmt(med["nightTime"] as TimeOfDay) : null;
      ReminderData.medicines.add({"title": name, "subtitle": meal ?? "No Meal Dependency"});
      await ApiService.saveMedicineReminder(
        name: name,
        dose: dose.isNotEmpty ? dose : null,
        meal: meal,
        morning: med["morning"] as bool,
        morningTime: morningTime,
        afternoon: med["afternoon"] as bool,
        afternoonTime: afternoonTime,
        night: med["night"] as bool,
        nightTime: nightTime,
        repeatDays: List<String>.from(med["repeatDays"] as List),
      );
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
                Text("Medicine Reminder", style: Theme.of(context).textTheme.headlineSmall),
              ]),
              const SizedBox(height: 24),
              ...medicines.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange, width: 1.2),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (medicines.length > 1)
                      Align(
                        alignment: Alignment.topRight,
                        child: Text("Medicine ${i + 1}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                      ),
                    _field(med["name"], "Medicine Name"),
                    _field(med["dose"], "Dose (e.g. 500mg)"),
                    _dropdown(med, mealOptions),
                    const SizedBox(height: 8),
                    const Text("Time", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _timeRow(medicines, i, "morning", "Morning"),
                    _timeRow(medicines, i, "afternoon", "Afternoon"),
                    _timeRow(medicines, i, "night", "Night"),
                    const SizedBox(height: 12),
                    const Text("Repeat Days", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _repeatChips(med),
                  ]),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _addField()),
                icon: const Icon(Icons.add, color: Colors.orange),
                label: const Text("Add Another Medicine", style: TextStyle(color: Colors.orange)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Save Medicines", style: TextStyle(color: Colors.white)),
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
        activeColor: Colors.orange,
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
          selectedColor: Colors.orange.shade100,
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