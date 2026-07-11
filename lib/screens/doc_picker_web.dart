// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

class PickedFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  PickedFile({required this.name, required this.bytes, required this.mimeType});
}

Future<PickedFile?> pickDocumentFile() async {
  final completer = Completer<PickedFile?>();
  final input = html.FileUploadInputElement();
  input.accept = '.pdf,.jpg,.jpeg,.png';
  input.click();
  input.onChange.listen((event) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        final bytes = reader.result as Uint8List;
        completer.complete(PickedFile(
          name: file.name,
          bytes: bytes,
          mimeType: file.type.isNotEmpty ? file.type : 'application/octet-stream',
        ));
      });
      reader.onError.listen((_) => completer.complete(null));
    } else {
      completer.complete(null);
    }
  });
  html.window.addEventListener('focus', (_) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!completer.isCompleted) completer.complete(null);
    });
  }, false);
  return completer.future;
}

Future<PickedFile?> pickCameraImage() async {
  final completer = Completer<PickedFile?>();
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.setAttribute('capture', 'environment');
  input.click();
  input.onChange.listen((event) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        final bytes = reader.result as Uint8List;
        completer.complete(PickedFile(
          name: file.name,
          bytes: bytes,
          mimeType: file.type.isNotEmpty ? file.type : 'image/jpeg',
        ));
      });
      reader.onError.listen((_) => completer.complete(null));
    } else {
      completer.complete(null);
    }
  });
  html.window.addEventListener('focus', (_) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!completer.isCompleted) completer.complete(null);
    });
  }, false);
  return completer.future;
}
