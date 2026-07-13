import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reminder_data.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';

import 'recently_tracked_hr_bp.dart';
import 'recently_uploaded_docs.dart';
import 'upload_new_docs.dart';
import 'upcoming_reminders.dart';
import 'add_appointment_reminder.dart';
import 'add_new_reminders.dart';
import 'cart.dart';
import 'notifications.dart';
import 'heart_rate_screen.dart';
import 'blood_pressure_screen.dart';
import 'share_cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _hrValue = '--';
  String _bpValue = '--';
  List<Map<String, dynamic>> _recentDocs = [];
  String? _realName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastReadings();
    _loadReminders();
    _loadDocuments();
  }

  Future<void> _loadProfile() async {
    final res = await ApiService.getProfile();
    if (res['success'] == true && res['data'] != null) {
      if (mounted) setState(() => _realName = res['data']['user']['name']);
    }
  }

  Future<void> _loadDocuments() async {
    final docs = await ApiService.getDocuments();
    if (mounted) setState(() => _recentDocs = docs);
  }

  Future<void> _loadReminders() async {
    final appointments = await ApiService.getAppointmentReminders();
    final medicines = await ApiService.getMedicineReminders();
    final tests = await ApiService.getTestReminders();

    ReminderData.appointments.clear();
    ReminderData.medicines.clear();
    ReminderData.tests.clear();

    for (final a in appointments) {
      ReminderData.appointments.add({
        'title': a['purpose'] as String? ?? 'Doctor Appointment',
        'subtitle': '${a['date'] ?? ''}${a['time'] != null ? ' • ${a['time']}' : ''}',
      });
    }
    for (final m in medicines) {
      ReminderData.medicines.add({
        'title': m['name'] as String? ?? '',
        'subtitle': m['meal'] as String? ?? 'No Meal Dependency',
      });
    }
    for (final t in tests) {
      ReminderData.tests.add({
        'title': t['name'] as String? ?? '',
        'subtitle': t['meal'] as String? ?? 'No Meal Dependency',
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadLastReadings() async {
    final hrRecords = await ApiService.getHeartRateRecords();
    final bpRecords = await ApiService.getBloodPressureRecords();
    if (hrRecords.isNotEmpty && mounted) {
      setState(() => _hrValue = '${hrRecords.first['bpm']}');
    }
    if (bpRecords.isNotEmpty && mounted) {
      setState(() => _bpValue = '${bpRecords.first['systolic']}/${bpRecords.first['diastolic']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = _realName ?? (widget.userEmail.contains("@")
        ? widget.userEmail.split('@')[0]
        : widget.userEmail);

    const Color softRed = Color(0xFFB71C1C);
    const Color deepTeal = Color(0xFF00695C);

    final cartCount = DocumentCartService().cart.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareCartScreen())).then((_) => setState((){}));
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              label: Text('Cart ($cartCount)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
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
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                            color:
                            Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                            fontSize: 22),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      buildIconButton(
                        icon: Icons.notifications_none,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotificationsScreen(
                                    userEmail:
                                    widget.userEmail,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 35),

              ////////////////////////////////////////////////////////////
              /// 🔔 UPCOMING REMINDERS (TOP)
              ////////////////////////////////////////////////////////////

              buildSectionTitle(
                context,
                "Upcoming Reminders",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UpcomingRemindersScreen(
                            userEmail:
                            widget.userEmail,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              if (ReminderData.appointments.isEmpty &&
                  ReminderData.medicines.isEmpty &&
                  ReminderData.tests.isEmpty)

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      "You are fit 😎💪\nNo upcoming reminders!\nDoctor missing you already 😂",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )

              else

                Column(
                  children: [

                    /// 🔵 APPOINTMENTS
                    ...ReminderData.appointments.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildReminderCard(
                          title: item["title"]!,
                          subtitle: item["subtitle"]!,
                          borderColor: Colors.blue,
                          icon: Icons.calendar_today,
                          iconColor: Colors.blue,
                        ),
                      );
                    }),

                    /// 🟠 MEDICINES
                    ...ReminderData.medicines.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildReminderCard(
                          title: item["title"]!,
                          subtitle: item["subtitle"]!,
                          borderColor: Colors.orange,
                          icon: Icons.medication,
                          iconColor: Colors.orange,
                        ),
                      );
                    }),

                    /// 🟢 TESTS  ← THIS WAS MISSING
                    ...ReminderData.tests.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildReminderCard(
                          title: item["title"]!,
                          subtitle: item["subtitle"]!,
                          borderColor: Colors.deepPurple,
                          icon: Icons.science,
                          iconColor: Colors.deepPurple,
                        ),
                      );
                    }),

                  ],
                ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _reminderButton(
                      label: "Appointment",
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddAppointmentReminderScreen(userEmail: widget.userEmail),
                      )).then((_) => _loadReminders()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _reminderButton(
                      label: "Medicine",
                      icon: Icons.medication,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddNewRemindersScreen(userEmail: widget.userEmail, initialSection: 'medicine'),
                      )).then((_) => _loadReminders()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _reminderButton(
                      label: "Test",
                      icon: Icons.science,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddNewRemindersScreen(userEmail: widget.userEmail, initialSection: 'test'),
                      )).then((_) => _loadReminders()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              ////////////////////////////////////////////////////////////
              /// ❤️ RECENTLY TRACKED
              ////////////////////////////////////////////////////////////

              buildSectionTitle(
                context,
                "Recently Tracked",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecentlyTrackedScreen(
                            userEmail:
                            widget.userEmail,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              /// ACTION BUTTONS
              // Row(
              //   children: [
              //     Expanded(
              //       child: buildActionButton(
              //           context,
              //           "+ Heart Rate"),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: buildActionButton(
              //           context,
              //           "+ Blood Pressure"),
              //     ),
              //   ],
              // ),
              //
              // const SizedBox(height: 18),

              /// HEART RATE + BP ROW
              Row(
                children: [
                  Expanded(
                    child: buildTrackingCard(
                      icon: Icons.favorite,
                      label: "HR",
                      value: _hrValue == '--' ? '--' : '$_hrValue bpm',
                      borderColor: softRed,
                      onAdd: () async {
                        final result = await Navigator.push<int>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HeartRateScreen()),
                        );
                        if (result != null) {
                          setState(() => _hrValue = '$result');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTrackingCard(
                      icon: Icons.monitor_heart,
                      label: "BP",
                      value: _bpValue == '--' ? '--' : '$_bpValue mmHg',
                      borderColor: deepTeal,
                      onAdd: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BloodPressureScreen()),
                        );
                        if (result != null) {
                          setState(() => _bpValue = result);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              ////////////////////////////////////////////////////////////
              /// 📄 RECENTLY UPLOADED
              ////////////////////////////////////////////////////////////

              buildSectionTitle(
                context,
                "Recently Uploaded",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecentlyUploadedDocs(
                            userEmail:
                            widget.userEmail,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              /// Document list from backend
              Builder(
                builder: (context) {
                  final docsToShow = _recentDocs.take(3).toList();

                  if (docsToShow.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Text(
                          "No documents uploaded yet.",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: docsToShow.map((doc) => _buildDocCard(doc)).toList(),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// Category filter buttons
              Row(
                children: [
                  Expanded(child: _buildCategoryButton("Prescription", Icons.medical_services_outlined, const Color(0xFF00897B))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCategoryButton("Report", Icons.science_outlined, const Color(0xFF283593))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCategoryButton("Insurance", Icons.favorite_border, const Color(0xFF2E7D32))),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// SECTION TITLE
  //////////////////////////////////////////////////////////////

  Widget buildSectionTitle(
      BuildContext context,
      String title,
      VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            fontSize: 18,
            fontWeight:
            FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            "View All",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  //////////////////////////////////////////////////////////////
  /// TRACKING CARD
  //////////////////////////////////////////////////////////////

  Widget buildTrackingCard({
    required IconData icon,
    required String label,
    required String value,
    required Color borderColor,
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: borderColor,
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Icon(Icons.add, size: 18, color: borderColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// ADD CARD
  //////////////////////////////////////////////////////////////

  Widget buildAddCard(Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
          vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: color,
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// REMINDER CARD
  //////////////////////////////////////////////////////////////

  Widget buildReminderCard({
    required String title,
    required String subtitle,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                  const TextStyle(
                    color:
                    Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// ICON BUTTON
  //////////////////////////////////////////////////////////////

  Widget buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: Icon(icon,
            color: AppColors.primary),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// ACTION BUTTON
  //////////////////////////////////////////////////////////////

  Widget buildActionButton(
      BuildContext context,
      String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
          vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontWeight:
              FontWeight.w600),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// PRIMARY BUTTON
  //////////////////////////////////////////////////////////////

  Widget _reminderButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget buildPrimaryButton(
      BuildContext context,
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

  //////////////////////////////////////////////////////////////
  /// DOCUMENT CARD
  //////////////////////////////////////////////////////////////

  void _handleMenuAction(String action, Map<String, dynamic> doc) async {
    final id = doc['id'];
    if (action == 'Add to Cart') {
      DocumentCartService().addToCart(doc);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Share Cart'), backgroundColor: AppColors.primary, duration: Duration(seconds: 1)),
      );
    } else if (action == 'Rename') {
      _showRenameDialog(id, doc['name'] ?? 'Document');
    } else if (action == 'Download') {
      final url = ApiService.resolveDocUrl(doc['file_url']);
      if (url.isNotEmpty) {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint("Error launching url: $e");
        }
      }
    } else if (action == 'Delete') {
      _confirmDeleteDoc(id, doc['name'] ?? 'Document');
    }
  }

  void _showRenameDialog(int id, String currentName) {
    final TextEditingController _renameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(controller: _renameController, decoration: const InputDecoration(hintText: "Enter new name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_renameController.text.trim().isNotEmpty) {
                final ok = await ApiService.renameDocument(id, _renameController.text.trim());
                if (ok) _loadDocuments();
              }
            },
            child: const Text('Rename', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDoc(int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ApiService.deleteDocument(id);
              if (ok) _loadDocuments();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final name = doc['name'] as String? ?? 'Document';
    final type = doc['type'] as String? ?? '';
    final createdAt = doc['created_at'] as String? ?? '';
    String formattedDate = createdAt;
    try {
      final dt = DateTime.parse(createdAt);
      formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(type, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (action) => _handleMenuAction(action, doc),
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Add to Cart', child: Text('Add to Cart')),
                  const PopupMenuItem(value: 'Rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'Download', child: Text('Download')),
                  const PopupMenuItem(value: 'Delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(formattedDate, style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// CATEGORY BUTTON
  //////////////////////////////////////////////////////////////

  Widget _buildCategoryButton(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadNewDocsScreen(
              userEmail: widget.userEmail,
              initialTab: label,
            ),
          ),
        ).then((_) => _loadDocuments());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}