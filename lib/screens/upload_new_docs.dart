import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';
import '../services/api_service.dart';
import 'doc_picker_stub.dart'
    if (dart.library.html) 'doc_picker_web.dart';

class UploadNewDocsScreen extends StatefulWidget {
  final String userEmail;
  final String initialTab;
  const UploadNewDocsScreen({super.key, required this.userEmail, this.initialTab = "Prescription"});

  @override
  State<UploadNewDocsScreen> createState() => _UploadNewDocsScreenState();
}

class _UploadNewDocsScreenState extends State<UploadNewDocsScreen> {
  late String selectedTab = widget.initialTab;
  String? selectedUploadFor;
  String? selectedCategory;
  PickedFile? _pickedFile;
  bool _uploading = false;

  final TextEditingController noteController = TextEditingController();
  final TextEditingController documentNameController = TextEditingController();
  final TextEditingController customCategoryController = TextEditingController();
  List<String> uploadForList = ["Myself"];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  void _loadFamilyMembers() async {
    final members = await ApiService.getFamilyMembers();
    if (mounted) {
      setState(() {
        for (var member in members) {
          uploadForList.add("${member['first_name']} ${member['last_name']}".trim());
        }
      });
    }
  }

  final List<String> categoryList = [
    "Orthopedic",
    "Gynac",
    "Cardiology",
    "General Physician",
    "Neurology",
    "Pediatrics",
    "Dermatology",
    "Ophthalmology",
    "ENT",
    "Psychiatry",
    "Custom..."
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomBottomNav(currentIndex: 1, userEmail: widget.userEmail),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _backButton(),
                const SizedBox(width: 12),
                Text("Upload Document", style: Theme.of(context).textTheme.headlineSmall),
              ]),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_tab("Prescription"), _tab("Report"), _tab("Insurance")],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedTab == "Report") ...[
                      _label("Category"),
                      const SizedBox(height: 10),
                      _dropdown("Select Category", selectedCategory, categoryList,
                          (v) => setState(() {
                            selectedCategory = v;
                            if (v != "Custom...") customCategoryController.clear();
                          })),
                      if (selectedCategory == "Custom...") ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: customCategoryController,
                          decoration: InputDecoration(
                            hintText: "Enter custom category",
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                    Row(children: [
                      Expanded(child: _btn("+ Add File", Icons.upload_file, _onAddFile)),
                      const SizedBox(width: 12),
                      Expanded(child: _btn("Camera", Icons.camera_alt_outlined, _onCamera)),
                    ]),
                    const SizedBox(height: 20),
                    if (_pickedFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('File Selected (${_pickedFile!.name.split('.').last.toUpperCase()})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _pickedFile = null;
                                  documentNameController.clear();
                                }),
                                child: const Icon(Icons.close, size: 16, color: Colors.black45),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            _label("Document Name"),
                            const SizedBox(height: 10),
                            TextField(
                              controller: documentNameController,
                              decoration: InputDecoration(
                                hintText: "Enter document name",
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (selectedUploadFor != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(children: [
                          const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text("For: $selectedUploadFor",
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => selectedUploadFor = null),
                            child: const Icon(Icons.close, size: 16, color: Colors.black45),
                          ),
                        ]),
                      ),
                    _label("Add Note"),
                    const SizedBox(height: 10),
                    _noteField(),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _uploading ? null : _upload,
                        child: _uploading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Upload Document", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first"), backgroundColor: Colors.red),
      );
      return;
    }
    if (documentNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a document name"), backgroundColor: Colors.red),
      );
      return;
    }

    String? finalCategory = selectedCategory;
    if (selectedTab == "Report" && selectedCategory == "Custom...") {
      if (customCategoryController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a custom category"), backgroundColor: Colors.red),
        );
        return;
      }
      finalCategory = customCategoryController.text.trim();
    }

    setState(() => _uploading = true);
    final ok = await ApiService.uploadDocument(
      name: documentNameController.text.trim(),
      type: selectedTab,
      category: finalCategory,
      uploadFor: selectedUploadFor,
      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
      fileBytes: _pickedFile!.bytes,
      fileName: _pickedFile!.name,
      mimeType: _pickedFile!.mimeType,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document uploaded successfully"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed. Try again."), backgroundColor: Colors.red),
      );
    }
  }

  void _onCamera() {
    _forWhomSheet((member) async {
      setState(() => selectedUploadFor = member);
      final picked = await pickCameraImage();
      if (picked != null && mounted) {
        setState(() {
          _pickedFile = picked;
          documentNameController.text = picked.name;
        });
      }
    });
  }

  void _onAddFile() {
    _forWhomSheet((member) async {
      setState(() => selectedUploadFor = member);
      final picked = await pickDocumentFile();
      if (picked != null && mounted) {
        setState(() {
          _pickedFile = picked;
          documentNameController.text = picked.name;
        });
      }
    });
  }

  void _forWhomSheet(void Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload for whom?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: uploadForList.map((m) => ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                    title: Text(m),
                    onTap: () { Navigator.pop(context); onSelected(m); },
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context),
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

  Widget _tab(String title) {
    final sel = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() {
        selectedTab = title;
        selectedCategory = null;
        selectedUploadFor = null;
        _pickedFile = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.primary)),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  Widget _btn(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options, Function(String) onSelect) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        backgroundColor: Colors.white,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((item) => ListTile(
                      title: Text(item),
                      trailing: value == item ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () { Navigator.pop(context); onSelect(item); },
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value ?? label, style: TextStyle(color: value == null ? Colors.black54 : Colors.black)),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: noteController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: "Write something...",
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}