import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAuthController extends ChangeNotifier {
  final FaceAuthIsolate _faceAuth = FaceAuthIsolate();
  bool _dbOnlyInitialized = false;

  FaceAuthState? _state;
  User? _user;
  List<Face>? _faces;
  Size? _imageSize;
  String? _errorMessage;

  FaceAuthState? get state => _state;
  User? get user => _user;
  List<Face>? get faces => _faces;
  Size? get imageSize => _imageSize;
  String? get errorMessage => _errorMessage;

  CameraService get cameraService => _faceAuth.cameraService;

  /// Initialize camera and face recognition isolate
  Future<void> initialize() async {
    try {
      await _faceAuth.initialize();
    } catch (e) {
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Initialize only database without camera services
  Future<void> initializeDatabaseOnly() async {
    if (!_dbOnlyInitialized) {
      try {
        await _faceAuth.initializeDatabaseOnly();
        _dbOnlyInitialized = true;
      } catch (e) {
        _errorMessage = 'Failed to initialize database: ${e.toString()}';
        notifyListeners();
        rethrow;
      }
    }
  }

  /// Register a new user
  Future<void> register({
    int samples = 4,
    void Function(User? user)? onDone,
    FaceAuthProgress? onProgress,
    void Function(String error)? onError,
    required String userId,
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
        userId: userId,
      );

      _setState(FaceAuthState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FaceAuthState.failed);
      onError?.call(_errorMessage!);
    }

    onDone?.call(_user);
  }

  /// Login existing user
  Future<void> login({
    void Function(User? user)? onDone,
    FaceAuthProgress? onProgress,
    void Function(String error)? onError,
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
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FaceAuthState.failed);
      onError?.call(_errorMessage!);
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
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

  Size get previewSize => Size(
        cameraService.cameraController!.value.previewSize!.height,
        cameraService.cameraController!.value.previewSize!.width,
      );

  /// Check if a user exists by ID
  Future<bool> userExists(String userId) async {
    await initializeDatabaseOnly();
    return await _faceAuth.userExists(userId);
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    await initializeDatabaseOnly();
    return await _faceAuth.getUserById(userId);
  }

  /// Delete user by ID
  Future<int> deleteUser(String userId) async {
    await initializeDatabaseOnly();
    return await _faceAuth.deleteUser(userId);
  }

  /// Get all registered users
  Future<List<User>> getAllUsers() async {
    await initializeDatabaseOnly();
    return await _faceAuth.getAllUsers();
  }

  /// Delete all users from database
  Future<void> deleteAllUsers() async {
    await initializeDatabaseOnly();
    return await _faceAuth.deleteDatabase();
  }
}
