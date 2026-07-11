import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import '../models/reminder_data.dart';

class AddNewRemindersScreen extends StatefulWidget {
  final String userEmail;

  const AddNewRemindersScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<AddNewRemindersScreen> createState() =>
      _AddNewRemindersScreenState();
}

class _AddNewRemindersScreenState
    extends State<AddNewRemindersScreen> {

  final placeController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final purposeController = TextEditingController();

  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> tests = [];

  final List<String> weekDays = [
    "Mon","Tue","Wed","Thu","Fri","Sat","Sun"
  ];

  final List<String> medicineMealOptions = [
    "After Meal",
    "With Meal",
    "Empty Stomach",
    "No Dependency",
  ];

  final List<String> testMealOptions = [
    "After Meal",
    "Empty Stomach",
    "No Dependency",
  ];

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
      "morning": false,
      "afternoon": false,
      "night": false,
      "morningTime": null,
      "afternoonTime": null,
      "nightTime": null,
      "repeatDays": <String>[],
    });
  }

  void addTestField() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        userEmail: widget.userEmail,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                children: [
                  buildBackButton(),
                  const SizedBox(width: 8),
                  Text(
                    "Add Reminder",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ////////////////////////////////////////////////////////////
              /// APPOINTMENT
              ////////////////////////////////////////////////////////////

              buildSectionCard(
                title: "Appointment",
                borderColor: Colors.blue,
                child: Column(
                  children: [
                    buildField(placeController, "Place"),
                    buildField(dateController, "Date"),
                    buildField(timeController, "Time"),
                    buildField(purposeController, "Purpose"),
                    const SizedBox(height: 10),
                    buildPrimaryButton(
                      "Add Appointment",
                          () {
                        if (dateController.text.isNotEmpty &&
                            timeController.text.isNotEmpty) {
                          ReminderData.appointments.add({
                            "title": purposeController.text.isEmpty
                                ? "Doctor Appointment"
                                : purposeController.text,
                            "subtitle":
                            "${dateController.text} • ${timeController.text}",
                          });
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HomeScreen(userEmail: widget.userEmail),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              ////////////////////////////////////////////////////////////
              /// MEDICINE
              ////////////////////////////////////////////////////////////

              buildSectionCard(
                title: "Medicine",
                borderColor: Colors.orange,
                child: Column(
                  children: [

                    ...medicines.asMap().entries.map((entry) {
                      int index = entry.key;
                      var med = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          buildField(med["name"], "Medicine Name"),
                          buildField(med["dose"], "Dose"),
                          buildMealDropdown(med, medicineMealOptions),

                          const SizedBox(height: 10),

                          buildTimeSelector(medicines, "Morning ☀️", index, "morning"),
                          buildTimeSelector(medicines, "Afternoon 🌤", index, "afternoon"),
                          buildTimeSelector(medicines, "Night 🌙", index, "night"),

                          const SizedBox(height: 12),

                          buildRepeatChips(med),

                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          addMedicineField();
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.orange),
                      label: const Text(
                        "Add Another Medicine",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),

                    const SizedBox(height: 10),

                    buildPrimaryButton(
                      "Save Medicines",
                          () {
                        for (var med in medicines) {
                          if (med["name"].text.isNotEmpty) {
                            ReminderData.medicines.add({
                              "title": med["name"].text,
                              "subtitle": med["meal"] ?? "No Meal Dependency",
                            });
                          }
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HomeScreen(userEmail: widget.userEmail),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              ////////////////////////////////////////////////////////////
              /// TEST
              ////////////////////////////////////////////////////////////

              buildSectionCard(
                title: "Test",
                borderColor: Colors.deepPurple,
                child: Column(
                  children: [

                    ...tests.asMap().entries.map((entry) {
                      int index = entry.key;
                      var test = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          buildField(test["name"], "Test Name"),
                          buildMealDropdown(test, testMealOptions),

                          const SizedBox(height: 10),

                          buildTimeSelector(tests, "Morning ☀️", index, "morning"),
                          buildTimeSelector(tests, "Afternoon 🌤", index, "afternoon"),
                          buildTimeSelector(tests, "Night 🌙", index, "night"),

                          const SizedBox(height: 12),

                          buildRepeatChips(test),

                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          addTestField();
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.deepPurple),
                      label: const Text(
                        "Add Another Test",
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),

                    const SizedBox(height: 10),

                    buildPrimaryButton(
                      "Save Tests",
                          () {
                        for (var test in tests) {
                          if (test["name"].text.isNotEmpty) {
                            ReminderData.tests.add({
                              "title": test["name"].text,
                              "subtitle": test["meal"] ?? "No Meal Dependency",
                            });
                          }
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HomeScreen(userEmail: widget.userEmail),
                          ),
                        );
                      },
                    )
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
  /// MEAL DROPDOWN
  //////////////////////////////////////////////////////////////

  Widget buildMealDropdown(
      Map<String, dynamic> item,
      List<String> options,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: item["meal"],
        decoration: const InputDecoration(
          labelText: "Meal Dependency",
          border: OutlineInputBorder(),
        ),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            item["meal"] = value;
          });
        },
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// TIME SELECTOR
  //////////////////////////////////////////////////////////////

  Widget buildTimeSelector(
      List<Map<String, dynamic>> list,
      String label,
      int index,
      String key,
      ) {

    bool selected = list[index][key];
    TimeOfDay? time =
    list[index]["${key}Time"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (val) async {
                setState(() {
                  list[index][key] = val;
                });

                if (val == true) {
                  TimeOfDay? picked =
                  await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      list[index]["${key}Time"] = picked;
                    });
                  }
                }
              },
            ),
            Text(label),
          ],
        ),

        if (selected && time != null)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              "Time: ${time.format(context)}",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),

        const SizedBox(height: 6),
      ],
    );
  }

  //////////////////////////////////////////////////////////////
  /// REPEAT CHIPS
  //////////////////////////////////////////////////////////////

  Widget buildRepeatChips(Map<String, dynamic> item) {
    return Wrap(
      spacing: 8,
      children: weekDays.map((day) {
        bool selected =
        item["repeatDays"].contains(day);

        return ChoiceChip(
          label: Text(day),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                item["repeatDays"].add(day);
              } else {
                item["repeatDays"].remove(day);
              }
            });
          },
        );
      }).toList(),
    );
  }

  //////////////////////////////////////////////////////////////
  /// COMMON WIDGETS
  //////////////////////////////////////////////////////////////

  Widget buildBackButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(userEmail: widget.userEmail),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget buildSectionCard({
    required String title,
    required Widget child,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget buildField(
      TextEditingController controller,
      String hint) {
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

  Widget buildPrimaryButton(
      String text,
      VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}