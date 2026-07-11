// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerBpCameraView(String viewId, html.VideoElement video) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) => video);
}

class BpCameraHelper {
  static void setupCamera(
    String viewId,
    void Function(dynamic stream) onStreamReady,
    void Function() onCameraError,
  ) {
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)';

    registerBpCameraView(viewId, video);

    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': {'facingMode': 'user'}, 'audio': false})
        .then((stream) {
      video.srcObject = stream;
      onStreamReady(stream);
    }).catchError((_) {
      onCameraError();
    });
  }

  static void stopStream(dynamic stream) {
    if (stream is html.MediaStream) {
      stream.getTracks().forEach((t) => t.stop());
    }
  }
}
