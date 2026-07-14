import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'home_screen.dart';
import 'upload_new_docs.dart';
import 'share_cart_screen.dart';

class RecentlyUploadedDocs extends StatefulWidget {
  final String userEmail;
  final String? filterFor;

  const RecentlyUploadedDocs({super.key, required this.userEmail, this.filterFor});

  @override
  State<RecentlyUploadedDocs> createState() => _RecentlyUploadedDocsState();
}

class _RecentlyUploadedDocsState extends State<RecentlyUploadedDocs> {
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final docs = await ApiService.getDocuments();
    if (mounted) {
      setState(() { 
        if (widget.filterFor != null) {
          _docs = docs.where((d) => d['upload_for'] == widget.filterFor).toList();
        } else {
          _docs = docs; 
        }
        _loading = false; 
      });
    }
  }

  Future<void> _delete(int id) async {
    final ok = await ApiService.deleteDocument(id);
    if (ok && mounted) {
      setState(() => _docs.removeWhere((d) => d['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); _delete(id); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
    } else if (action == 'AI Analysis') {
      _runAIAnalysis(id, doc['name'] ?? 'Document');
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
      _confirmDelete(id, doc['name'] ?? 'Document');
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
                if (ok) _load();
              }
            },
            child: const Text('Rename', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _runAIAnalysis(int id, String name) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Analyzing Report with AI...", style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    final res = await ApiService.analyzeDocument(id);
    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] == true && res['analysis'] != null) {
      _showAnalysisSheet(name, res['analysis']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to analyze report'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAnalysisSheet(String name, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                            SizedBox(width: 8),
                            Text("AI Insights Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...content.split('\n').map((line) {
                      final trimmed = line.trim();
                      if (trimmed.startsWith('###')) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Text(
                            trimmed.replaceAll('###', '').trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                          ),
                        );
                      } else if (trimmed.startsWith('##')) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Text(
                            trimmed.replaceAll('##', '').trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          ),
                        );
                      } else if (trimmed.startsWith('#')) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: Text(
                            trimmed.replaceAll('#', '').trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                        );
                      } else if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                              Expanded(
                                child: Text(
                                  trimmed.substring(1).trim().replaceAll('**', ''),
                                  style: const TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (trimmed.isEmpty) {
                        return const SizedBox(height: 10);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          trimmed.replaceAll('**', ''),
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final doc in _docs) {
      final type = (doc['type'] as String?) ?? 'Other';
      grouped.putIfAbsent(type, () => []).add(doc);
    }

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
      bottomNavigationBar: CustomBottomNav(currentIndex: 1, userEmail: widget.userEmail),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _backButton(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.filterFor != null ? "${widget.filterFor}'s Documents" : 'Documents', 
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 30),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _docs.isEmpty
                        ? const Center(child: Text('No documents uploaded yet', style: TextStyle(color: Colors.black54)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              children: grouped.entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 12),
                                    ...entry.value.map((doc) => Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _docCard(doc),
                                    )),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => UploadNewDocsScreen(userEmail: widget.userEmail),
                    ));
                    _load();
                  },
                  child: const Text('+ Upload Document', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docCard(Map<String, dynamic> doc) {
    final name = (doc['name'] as String?) ?? 'Unnamed';
    final category = (doc['category'] as String?) ?? '';
    final uploadFor = (doc['upload_for'] as String?) ?? '';
    final note = (doc['note'] as String?) ?? '';
    final id = doc['id'] as int;
    final fileUrl = ApiService.resolveDocUrl(doc['file_url'] as String?);

    return GestureDetector(
      onTap: () async {
        if (fileUrl.isNotEmpty) {
          try {
            await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint("Error launching url: $e");
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insert_drive_file, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                  if (category.isNotEmpty || uploadFor.isNotEmpty)
                    Text(
                      [if (category.isNotEmpty) category, if (uploadFor.isNotEmpty) uploadFor].join(' • '),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  if (note.isNotEmpty)
                    Text(note, style: const TextStyle(fontSize: 12, color: Colors.black45), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 22),
              tooltip: 'Add to Cart',
              onPressed: () => _handleMenuAction('Add to Cart', doc),
            ),
            PopupMenuButton<String>(
              onSelected: (action) => _handleMenuAction(action, doc),
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Add to Cart', child: Text('Add to Cart')),
                const PopupMenuItem(value: 'AI Analysis', child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('AI Analysis'),
                  ],
                )),
                const PopupMenuItem(value: 'Rename', child: Text('Rename')),
                const PopupMenuItem(value: 'Download', child: Text('Download')),
                const PopupMenuItem(value: 'Delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(userEmail: widget.userEmail),
      )),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.primary),
      ),
    );
  }
}
