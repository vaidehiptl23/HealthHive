// Stub for non-web platforms
void registerBpCameraView(String viewId, dynamic video) {}

class BpCameraHelper {
  static void setupCamera(
    String viewId,
    void Function(dynamic stream) onStreamReady,
    void Function() onCameraError,
  ) {}

  static void stopStream(dynamic stream) {}
}
