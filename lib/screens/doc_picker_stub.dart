import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  PickedFile({required this.name, required this.bytes, required this.mimeType});
}

Future<PickedFile?> pickDocumentFile() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path;
      Uint8List? bytes = file.bytes;
      if (bytes == null && path != null) {
        bytes = await File(path).readAsBytes();
      }
      if (bytes != null) {
        final ext = file.name.split('.').last.toLowerCase();
        String mimeType = 'application/octet-stream';
        if (ext == 'pdf') mimeType = 'application/pdf';
        if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
        if (ext == 'png') mimeType = 'image/png';
        
        return PickedFile(
          name: file.name,
          bytes: bytes,
          mimeType: mimeType,
        );
      }
    }
  } catch (e) {
    // Silent fail or logging
  }
  return null;
}

Future<PickedFile?> pickCameraImage() async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      
      return PickedFile(
        name: file.name,
        bytes: bytes,
        mimeType: mimeType,
      );
    }
  } catch (e) {
    // Silent fail or logging
  }
  return null;
}