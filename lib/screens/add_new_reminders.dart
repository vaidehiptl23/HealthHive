import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../models/reminder_data.dart';
import '../services/api_service.dart';

class AddNewRemindersScreen extends StatefulWidget {
  final String userEmail;
  // 'medicine' shows only medicine form, 'test' shows only test form
  final String initialSection;
  const AddNewRemindersScreen({super.key, required this.userEmail, this.initialSection = 'medicine'});

  @override
  State<AddNewRemindersScreen> createState() => _AddNewRemindersScreenState();
}

class _AddNewRemindersScreenState extends State<AddNewRemindersScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _medicineKey = GlobalKey();
  final GlobalKey _testKey = GlobalKey();

  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> tests = [];

  final List<String> weekDays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
  final List<String> medicineMealOptions = ["After Meal","With Meal","Empty Stomach","No Dependency"];
  final List<String> testMealOptions = ["After Meal","Empty Stomach","No Dependency"];

  @override
  void initState() {
    super.initState();
    addMedicineField();
    addTestField();
  }

  void addMedicineField() {
    medicines.add({
      "name": TextEditingController(),
      "dose": TextEditingController(),
      "meal": null,
      "morning": false, "afternoon": false, "night": false,
      "morningTime": null, "afternoonTime": null, "nightTime": null,
      "repeatDays": <String>[],
    });
  }

  void addTestField() {
    tests.add({
      "name": TextEditingController(),
      "meal": null,
      "morning": false, "afternoon": false, "night": false,
      "morningTime": null, "afternoonTime": null, "nightTime": null,
      "repeatDays": <String>[],
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomBottomNav(currentIndex: 3, userEmail: widget.userEmail),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                buildBackButton(),
                const SizedBox(width: 8),
                Text(
                  widget.initialSection == 'medicine' ? "Medicine Reminder" : "Test Reminder",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ]),
              const SizedBox(height: 30),

              // MEDICINE — shown only when initialSection == 'medicine'
              if (widget.initialSection == 'medicine') ...[
                buildSectionCard(
                  key: _medicineKey,
                  title: "Medicine",
                  borderColor: Colors.orange,
                  child: Column(children: [
                    ...medicines.asMap().entries.map((entry) {
                      int index = entry.key;
                      var med = entry.value;
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        buildField(med["name"], "Medicine Name"),
                        buildField(med["dose"], "Dose"),
                        buildMealDropdown(med, medicineMealOptions),
                        const SizedBox(height: 10),
                        buildTimeSelector(medicines, "☀️", "Morning", index, "morning"),
                        buildTimeSelector(medicines, "🌤", "Afternoon", index, "afternoon"),
                        buildTimeSelector(medicines, "🌙", "Night", index, "night"),
                        const SizedBox(height: 12),
                        buildRepeatChips(med),
                        const SizedBox(height: 20),
                      ]);
                    }),
                    TextButton.icon(
                      onPressed: () => setState(() => addMedicineField()),
                      icon: const Icon(Icons.add, color: Colors.orange),
                      label: const Text("Add Another Medicine", style: TextStyle(color: Colors.orange)),
                    ),
                    const SizedBox(height: 10),
                    buildPrimaryButton("Save Medicines", () async {
                      for (var med in medicines) {
                        if ((med["name"] as TextEditingController).text.isNotEmpty) {
                          final name = (med["name"] as TextEditingController).text;
                          final dose = (med["dose"] as TextEditingController).text;
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
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                    }),
                  ]),
                ),
              ],

              // TEST — shown only when initialSection == 'test'
              if (widget.initialSection == 'test') ...[
                buildSectionCard(
                  key: _testKey,
                  title: "Test",
                  borderColor: Colors.deepPurple,
                  child: Column(children: [
                    ...tests.asMap().entries.map((entry) {
                      int index = entry.key;
                      var test = entry.value;
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        buildField(test["name"], "Test Name"),
                        buildMealDropdown(test, testMealOptions),
                        const SizedBox(height: 10),
                        buildTimeSelector(tests, "☀️", "Morning", index, "morning"),
                        buildTimeSelector(tests, "🌤", "Afternoon", index, "afternoon"),
                        buildTimeSelector(tests, "🌙", "Night", index, "night"),
                        const SizedBox(height: 12),
                        buildRepeatChips(test),
                        const SizedBox(height: 20),
                      ]);
                    }),
                    TextButton.icon(
                      onPressed: () => setState(() => addTestField()),
                      icon: const Icon(Icons.add, color: Colors.deepPurple),
                      label: const Text("Add Another Test", style: TextStyle(color: Colors.deepPurple)),
                    ),
                    const SizedBox(height: 10),
                    buildPrimaryButton("Save Tests", () async {
                      for (var test in tests) {
                        if ((test["name"] as TextEditingController).text.isNotEmpty) {
                          final name = (test["name"] as TextEditingController).text;
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
                        }
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                    }),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMealDropdown(Map<String, dynamic> item, List<String> options) {
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

  Widget buildTimeSelector(List<Map<String, dynamic>> list, String emoji, String label, int index, String key) {
    bool selected = list[index][key] as bool;
    TimeOfDay? time = list[index]["${key}Time"] as TimeOfDay?;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Checkbox(value: selected, onChanged: (val) async {
          setState(() => list[index][key] = val);
          if (val == true) {
            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (picked != null && mounted) setState(() => list[index]["${key}Time"] = picked);
          }
        }),
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(label),
      ]),
      if (selected && time != null)
        Padding(padding: const EdgeInsets.only(left: 40),
          child: Text("Time: ${time.format(context)}", style: const TextStyle(fontSize: 13, color: Colors.black54))),
      const SizedBox(height: 6),
    ]);
  }

  Widget buildRepeatChips(Map<String, dynamic> item) {
    return Wrap(spacing: 8, children: weekDays.map((day) {
      bool selected = (item["repeatDays"] as List<String>).contains(day);
      return ChoiceChip(label: Text(day), selected: selected, onSelected: (val) => setState(() {
        if (val) (item["repeatDays"] as List<String>).add(day);
        else (item["repeatDays"] as List<String>).remove(day);
      }));
    }).toList());
  }

  Widget buildBackButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.arrow_back, color: AppColors.primary),
      ),
    );
  }

  Widget buildSectionCard({Key? key, required String title, required Widget child, required Color borderColor}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget buildField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder())),
    );
  }

  Widget buildPrimaryButton(String text, VoidCallback onTap) {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, child: Text(text)));
  }
}
