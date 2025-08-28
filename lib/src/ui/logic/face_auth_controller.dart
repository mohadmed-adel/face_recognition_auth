import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAuthController extends ChangeNotifier {
  final FaceAuthIsolate _faceAuth = FaceAuthIsolate();

  FaceAuthState? _state;
  User? _user;
  List<Face>? _faces;
  Size? _imageSize;

  FaceAuthState? get state => _state;
  User? get user => _user;
  List<Face>? get faces => _faces;
  Size? get imageSize => _imageSize;

  CameraService get cameraService => _faceAuth.cameraService;

  /// Initialize camera and face recognition isolate
  Future<void> initialize() async {
    await _faceAuth.initialize();
  }

  /// Register a new user
  Future<void> register({
    int samples = 4,
    void Function(User? user)? onDone,
    FaceAuthProgress? onProgress,
  }) async {
    _resetUser();
    _setState(FaceAuthState.cameraOpened);

    try {
      _user = await _faceAuth.registerWithCamera(
        requiredSamples: samples,
        onProgress: (data) {
          _setState(data);
          onProgress?.call(data);
        },
        onFaceDetected: _updateFace,
      );

      _setState(FaceAuthState.success);
    } catch (_) {
      _setState(FaceAuthState.failed);
    }

    onDone?.call(_user);
  }

  /// Login existing user
  Future<void> login({
    void Function(User? user)? onDone,
    FaceAuthProgress? onProgress,
  }) async {
    _resetUser();
    _setState(FaceAuthState.cameraOpened);

    try {
      _user = await _faceAuth.loginWithCamera(
        onFaceDetected: _updateFace,
        onProgress: (data) {
          _setState(data);
          onProgress?.call(data);
        },
      );

      _setState(FaceAuthState.success);
    } catch (_) {
      _setState(FaceAuthState.failed);
    }

    onDone?.call(_user);
  }

  /// Update the controller state
  void _setState(FaceAuthState state) {
    _state = state;
    notifyListeners();
  }

  /// Update detected faces
  void _updateFace(List<Face>? faces, CameraImage image) {
    _faces = faces;
    _imageSize ??= previewSize;
    notifyListeners();
  }

  /// Reset user before login/register
  void _resetUser() {
    _user = null;
    _faces = null;
  }

  /// Clean up resources
  @override
  void dispose() {
    _stopCameraStream();
    cameraService.cameraController?.dispose();
    _faceAuth.cameraService.dispose();
    _faceAuth.dispose();
    super.dispose();
  }

  void _stopCameraStream() {
    final controller = cameraService.cameraController;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
  }

  /// Helpers for image size
  Size _calculateImageSize(CameraImage? image) {
    if (image == null) return Size.zero;
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Size get previewSize => Size(
        cameraService.cameraController!.value.previewSize!.height,
        cameraService.cameraController!.value.previewSize!.width,
      );
}
