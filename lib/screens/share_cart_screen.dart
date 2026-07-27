import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import '../utils/colors.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';

class ShareCartScreen extends StatefulWidget {
  const ShareCartScreen({super.key});

  @override
  State<ShareCartScreen> createState() => _ShareCartScreenState();
}

class _ShareCartScreenState extends State<ShareCartScreen> {
  final DocumentCartService _cartService = DocumentCartService();
  bool _isSharing = false;

  void _removeFromCart(int id) {
    setState(() {
      _cartService.removeFromCart(id);
    });
  }

  Future<void> _shareDocuments() async {
    if (_cartService.cart.isEmpty) return;

    // Check if there is a mix of PDFs and images in the cart
    bool hasPdf = false;
    bool hasImage = false;
    for (var doc in _cartService.cart) {
      final mime = (doc['mime_type'] as String? ?? '').toLowerCase();
      if (mime.contains('pdf')) hasPdf = true;
      if (mime.contains('image/') || mime.contains('jpg') || mime.contains('png') || mime.contains('jpeg')) {
        hasImage = true;
      }
    }

    if (hasPdf && hasImage && !kIsWeb) {
      // Prompt user with a choice to zip or share directly
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Options'),
          content: const Text(
            'You are sharing a mix of PDFs and images. Third-party apps like WhatsApp do not support sending mixed file types directly.\n\nWould you like to bundle them as a single folder (.zip) for WhatsApp, or try sending them separately?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'separate'),
              child: const Text('Send Separately'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'zip'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Send Zipped (.zip)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (choice == null) return;
      if (choice == 'zip') {
        _shareAsZip();
        return;
      }
    }

    _shareDirect();
  }

  Future<void> _shareAsZip() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final encoder = ZipFileEncoder();
      final zipPath = '${tempDir.path}/healthhive_documents_${DateTime.now().millisecondsSinceEpoch}.zip';
      encoder.create(zipPath);

      int counter = 0;
      for (var doc in _cartService.cart) {
        final url = ApiService.resolveDocUrl(doc['file_url'] as String?);
        final name = doc['name'] as String? ?? 'Document';
        if (url.isNotEmpty) {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final mimeType = doc['mime_type'] as String? ?? 'application/octet-stream';
            String ext = 'pdf';
            if (mimeType == 'application/pdf') {
              ext = 'pdf';
            } else if (mimeType == 'image/png') {
              ext = 'png';
            } else if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
              ext = 'jpg';
            } else {
              final cleanUrl = url.split('?').first;
              final fileExt = cleanUrl.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
              if (fileExt.isNotEmpty && fileExt.length <= 4) {
                ext = fileExt;
              }
            }
            final safeName = name.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
            final fileName = counter == 0 ? '$safeName.$ext' : '${safeName}_$counter.$ext';
            counter++;

            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(response.bodyBytes);
            
            encoder.addFile(tempFile);
          }
        }
      }

      encoder.close();

      final zipFile = File(zipPath);
      if (await zipFile.exists() && counter > 0) {
        await Share.shareXFiles(
          [XFile(zipPath, name: 'healthhive_documents.zip', mimeType: 'application/zip')],
          text: 'Here are my health documents.',
        );
        setState(() { _cartService.clearCart(); });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to package documents'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating zip: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _shareDirect() async {
    setState(() {
      _isSharing = true;
    });

    try {
      if (kIsWeb) {
        // Fallback for Web: Web browsers block cross-domain byte fetching (CORS) 
        // and Web Share API is weak. We'll simply trigger direct downloads! 
        for (var doc in _cartService.cart) {
          final url = ApiService.resolveDocUrl(doc['file_url'] as String?);
          if (url.isNotEmpty) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        }
        setState(() { _cartService.clearCart(); });
      } else {
        // Native Mobile (Android/iOS): Fetch bytes and use native Share Sheet to WhatsApp/Gmail
        List<XFile> xFiles = [];
        String debugMsg = "Unknown";
        final tempDir = await getTemporaryDirectory();
        int counter = 0;

        for (var doc in _cartService.cart) {
          final url = ApiService.resolveDocUrl(doc['file_url'] as String?);
          final name = doc['name'] as String? ?? 'Document';
          
          if (url.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(url));
              if (response.statusCode == 200) {
                final mimeType = doc['mime_type'] as String? ?? 'application/octet-stream';
                
                // Determine file extension accurately from mimeType
                String ext = 'pdf';
                if (mimeType == 'application/pdf') {
                  ext = 'pdf';
                } else if (mimeType == 'image/png') {
                  ext = 'png';
                } else if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
                  ext = 'jpg';
                } else {
                  // Fallback: parse extension from URL
                  final cleanUrl = url.split('?').first;
                  final fileExt = cleanUrl.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
                  if (fileExt.isNotEmpty && fileExt.length <= 4) {
                    ext = fileExt;
                  }
                }

                final safeName = name.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
                // Use the document name directly in the file path so the receiver gets the proper name
                final fileName = counter == 0 ? '$safeName.$ext' : '${safeName}_$counter.$ext';
                final tempFile = File('${tempDir.path}/$fileName');
                counter++;
                
                await tempFile.writeAsBytes(response.bodyBytes);
                
                xFiles.add(XFile(
                  tempFile.path, 
                  name: fileName,
                  mimeType: mimeType,
                ));
              } else {
                debugMsg = "Code ${response.statusCode}";
              }
            } catch (e) {
              debugMsg = "Error: $e";
            }
          }
        }

        if (xFiles.isNotEmpty) {
          // Share all documents together using the native sharing sheet
          await Share.shareXFiles(xFiles, text: 'Here are my health documents.');
          setState(() { _cartService.clearCart(); });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $debugMsg'), backgroundColor: Colors.red));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartService.cart;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Share Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(child: Text('Your cart is empty', style: TextStyle(fontSize: 16, color: Colors.black54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final doc = cartItems[index];
                        final name = doc['name'] ?? 'Unnamed';
                        final type = doc['type'] ?? 'Unknown';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(type, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeFromCart(doc['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSharing ? null : _shareDocuments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSharing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Share ${cartItems.length} Documents', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
