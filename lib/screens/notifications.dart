import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String userEmail;

  const NotificationsScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final res = await ApiService.getNotifications();
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          notifications = res['data'] ?? [];
          isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> markAsRead(int index) async {
    final item = notifications[index];
    final res = await ApiService.markNotificationAsRead(item['id']);
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          notifications[index]['is_read'] = 1;
        });
      }
    }
  }

  //////////////////////////////////////////////////////////////
  /// SNOOZE
  //////////////////////////////////////////////////////////////

  void snoozeNotification(int index) async {
    TimeOfDay? selectedTime =
    await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
              "Snoozed until ${selectedTime.format(context)}"),
        ),
      );

      setState(() {
        notifications.removeAt(index);
      });
    }
  }

  //////////////////////////////////////////////////////////////
  /// BUILD
  //////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar:
      CustomBottomNav(
        currentIndex: 0,
        userEmail: widget.userEmail,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              ////////////////////////////////////////////////////////////
              /// ✅ HEADER (Now Same As Cart Screen)
              ////////////////////////////////////////////////////////////
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  buildCloseButton(context),
                ],
              ),

              const SizedBox(height: 30),

              ////////////////////////////////////////////////////////////
              /// LIST
              ////////////////////////////////////////////////////////////
              ////////////////////////////////////////////////////////////
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                    ? Center(
                  child: Text(
                    "No notifications",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                )
                    : ListView.builder(
                  itemCount:
                  notifications.length,
                  itemBuilder:
                      (context, index) {
                    final item =
                    notifications[index];

                    return Padding(
                      padding:
                      const EdgeInsets
                          .only(bottom: 16),
                      child:
                      buildNotificationCard(
                        index,
                        item["message"],
                        item["is_read"] == 1 || item["is_read"] == true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// NOTIFICATION CARD
  //////////////////////////////////////////////////////////////

  Widget buildNotificationCard(
      int index,
      String message,
      bool isRead) {
    return AnimatedOpacity(
      duration:
      const Duration(milliseconds: 300),
      opacity: isRead ? 0.5 : 1,
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            Text(
              message,
              style: const TextStyle(
                fontWeight:
                FontWeight.w600,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [

                TextButton(
                  onPressed: isRead
                      ? null
                      : () =>
                      markAsRead(
                          index),
                  child: const Text(
                    "Mark as Read",
                    style: TextStyle(
                        color:
                        AppColors.primary),
                  ),
                ),

                TextButton(
                  onPressed: () =>
                      snoozeNotification(
                          index),
                  child: const Text(
                    "Snooze",
                    style: TextStyle(
                        color:
                        AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// CLOSE BUTTON (Same As Cart)
  //////////////////////////////////////////////////////////////

  Widget buildCloseButton(
      BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userEmail:
              widget.userEmail,
            ),
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
              12),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: const Icon(
          Icons.close,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
