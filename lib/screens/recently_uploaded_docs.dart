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
