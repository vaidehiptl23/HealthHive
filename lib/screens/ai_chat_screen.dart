import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class AIChatScreen extends StatefulWidget {
  final String userEmail;

  const AIChatScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<AIChatScreen> createState() =>
      _AIChatScreenState();
}

class _AIChatScreenState
    extends State<AIChatScreen> {

  final TextEditingController messageController =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();

  final List<Map<String, String>> messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    /// Default AI welcome message
    messages.add({
      "type": "ai",
      "text":
      "I'm your HealthHive AI assistant. How can I help you with your health today?",
    });
  }

  //////////////////////////////////////////////////////////////
  /// SEND MESSAGE
  //////////////////////////////////////////////////////////////

  Future<void> sendMessage() async {
    String userMessage =
    messageController.text.trim();

    if (userMessage.isEmpty || _isTyping) return;

    setState(() {
      messages.add({
        "type": "user",
        "text": userMessage,
      });
      _isTyping = true;
    });

    messageController.clear();
    _scrollToBottom();

    // Call the backend (which calls Ollama)
    final reply = await ApiService.sendChatMessage(userMessage);

    if (!mounted) return;

    setState(() {
      messages.add({
        "type": "ai",
        "text": reply,
      });
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100),
          () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  //////////////////////////////////////////////////////////////
  /// BUILD
  //////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        userEmail: widget.userEmail,
      ),

      body: SafeArea(
        child: Column(
          children: [

            //////////////////////////////////////////////////////////////
            /// UPDATED HEADER (Same as Upcoming Screen)
            //////////////////////////////////////////////////////////////
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  buildBackButton(context),
                  const SizedBox(width: 8),
                  Text(
                    "AI Assistant",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ],
              ),
            ),

            //////////////////////////////////////////////////////////////
            /// CHAT AREA
            //////////////////////////////////////////////////////////////
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10),
                itemCount: messages.length + (_isTyping ? 1 : 0),
                itemBuilder:
                    (context, index) {

                  // Typing indicator as the last item
                  if (index == messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }

                  final msg =
                  messages[index];

                  bool isUser =
                      msg["type"] ==
                          "user";

                  return Align(
                    alignment: isUser
                        ? Alignment
                        .centerRight
                        : Alignment
                        .centerLeft,
                    child: Container(
                      margin:
                      const EdgeInsets
                          .only(
                          bottom:
                          14),
                      padding:
                      const EdgeInsets
                          .all(16),
                      constraints:
                      const BoxConstraints(
                        maxWidth: 280,
                      ),
                      decoration:
                      BoxDecoration(
                        color: isUser
                            ? AppColors
                            .primary
                            .withOpacity(
                            0.15)
                            : Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(
                            16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                                0.05),
                            blurRadius:
                            8,
                          )
                        ],
                      ),
                      child: Text(
                        msg["text"]!,
                        style: Theme.of(
                            context)
                            .textTheme
                            .bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),

            if (messages.length == 1)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _suggestionChip("🌡️ Check Symptoms", "I would like to do an AI symptom check. I am feeling unwell."),
                      _suggestionChip("🥗 Diet Tips", "Give me some personalized healthy diet recommendations."),
                      _suggestionChip("❤️ Lower Blood Pressure", "What are some natural ways to lower high blood pressure?"),
                    ],
                  ),
                ),
              ),

            //////////////////////////////////////////////////////////////
            /// INPUT FIELD
            //////////////////////////////////////////////////////////////
            Container(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14),
              decoration:
              const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black12,
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      messageController,
                      onSubmitted: (_) => sendMessage(),
                      textInputAction: TextInputAction.send,
                      decoration:
                      InputDecoration(
                        hintText:
                        "Ask about your health...",
                        filled: true,
                        fillColor:
                        AppColors
                            .background,
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                              25),
                          borderSide:
                          BorderSide
                              .none,
                        ),
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                            horizontal:
                            16,
                            vertical:
                            12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isTyping ? null : sendMessage,
                    child: Container(
                      padding:
                      const EdgeInsets
                          .all(12),
                      decoration:
                      BoxDecoration(
                        color: _isTyping
                            ? Colors.grey
                            : AppColors.primary,
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// TYPING INDICATOR
  //////////////////////////////////////////////////////////////

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: const BoxConstraints(maxWidth: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2 - 1).abs().clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////
  /// MODERN BACK BUTTON (Reusable Style)
  //////////////////////////////////////////////////////////////

  Widget buildBackButton(BuildContext context) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(
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
          BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _suggestionChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          messageController.text = prompt;
          sendMessage();
        },
      ),
    );
  }
}
