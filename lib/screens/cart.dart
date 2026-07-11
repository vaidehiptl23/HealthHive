import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';

class CartScreen extends StatelessWidget {
  final String userEmail;

  const CartScreen({
    super.key,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    List<String> documents = [
      "Prescription Report.pdf",
      "Blood Test Result.pdf",
      "Insurance Copy.pdf",
      "MRI Scan Report.pdf",
    ];

    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        userEmail: userEmail,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cart",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  buildIconButton(context),
                ],
              ),

              const SizedBox(height: 30),

              /// DOCUMENT LIST
              Expanded(
                child: documents.isEmpty
                    ? Center(
                  child: Text(
                    "No documents added",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                )
                    : ListView.builder(
                  itemCount:
                  documents.length,
                  itemBuilder:
                      (context, index) {
                    return Padding(
                      padding:
                      const EdgeInsets
                          .only(
                          bottom: 16),
                      child:
                      buildDocumentCard(
                          documents[
                          index]),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// SHARE BUTTON
              buildPrimaryButton(
                context,
                "Share Documents",
                    () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                      Text("Shared successfully"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// DOCUMENT CARD
  //////////////////////////////////////////////////////////////

  Widget buildDocumentCard(String title) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [

          /// FILE ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withOpacity(0.1),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          /// FILE NAME
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight:
                FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// PRIMARY BUTTON
  //////////////////////////////////////////////////////////////

  Widget buildPrimaryButton(
      BuildContext context,
      String text,
      VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          AppColors.primary,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
                14),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight:
            FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// CLOSE ICON BUTTON
  //////////////////////////////////////////////////////////////

  Widget buildIconButton(BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userEmail: userEmail,
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
