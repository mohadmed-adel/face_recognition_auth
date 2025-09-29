import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAuthController extends ChangeNotifier {
  final FaceAuthIsolate _faceAuth = FaceAuthIsolate();
  bool _dbOnlyInitialized = false;
  bool _disposed = false;

  FaceAuthState? _state;
  User? _user;
  List<Face>? _faces;
  Size? _imageSize;
  String? _errorMessage;

  // Anti-spoofing related state
  AntiSpoofingResult? _antiSpoofingResult;
  AntiSpoofingConfig _antiSpoofingConfig =
      AntiSpoofingConfig.handShakeResistant();
  List<String> _livenessPrompts = [];
  bool _showLivenessPrompt = false;

  FaceAuthState? get state => _state;
  User? get user => _user;
  List<Face>? get faces => _faces;
  Size? get imageSize => _imageSize;
  String? get errorMessage => _errorMessage;
  bool get isDisposed => _disposed;

  // Anti-spoofing getters
  AntiSpoofingResult? get antiSpoofingResult => _antiSpoofingResult;
  AntiSpoofingConfig get antiSpoofingConfig => _antiSpoofingConfig;
  List<String> get livenessPrompts => _livenessPrompts;
  bool get showLivenessPrompt => _showLivenessPrompt;

  CameraService get cameraService => _faceAuth.cameraService;

  /// Configure anti-spoofing settings
  void configureAntiSpoofing(AntiSpoofingConfig config) {
    if (_disposed) return;
    _antiSpoofingConfig = config;
    // Note: FaceAuthIsolate doesn't have configureAntiSpoofing method
    // The configuration will be passed when calling register/login methods
    notifyListeners();
  }

  /// Update liveness prompts for user guidance
  void _updateLivenessPrompts(List<String> prompts) {
    if (_disposed) return;
    _livenessPrompts = prompts;
    _showLivenessPrompt = prompts.isNotEmpty;
    notifyListeners();
  }

  /// Clear liveness prompts
  void _clearLivenessPrompts() {
    if (_disposed) return;
    _livenessPrompts.clear();
    _showLivenessPrompt = false;
    notifyListeners();
  }

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
    FaceAuthErrorCallback? onError,
    required String userId,
    AntiSpoofingConfig? antiSpoofingConfig,
  }) async {
    if (_disposed) throw StateError('Controller is disposed');
    _resetUser();
    _setState(FaceAuthState.cameraOpened);

    try {
      _user = await _faceAuth.registerWithCamera(
        requiredSamples: samples,
        onProgress: (data) {
          _setState(data);
          _handleAntiSpoofingState(data);
          onProgress?.call(data);
        },
        onFaceDetected: _updateFace,
        onError: (error) {
          _errorMessage = error.userMessage;
          _setState(FaceAuthState.failed);
          _clearLivenessPrompts();
          onError?.call(error);
        },
        userId: userId,
        antiSpoofingConfig: antiSpoofingConfig,
      );

      _setState(FaceAuthState.success);
      _clearLivenessPrompts();
    } catch (e) {
      // Convert error to FaceAuthError if it's not already
      final faceAuthError =
          e is FaceAuthError ? e : FaceAuthError.fromMessage(e.toString());

      _errorMessage = faceAuthError.userMessage;
      _setState(FaceAuthState.failed);
      _clearLivenessPrompts();
      onError?.call(faceAuthError);
    }

    onDone?.call(_user);
  }

  /// Login existing user
  Future<void> login({
    void Function(User? user)? onDone,
    FaceAuthProgress? onProgress,
    FaceAuthErrorCallback? onError,
    AntiSpoofingConfig? antiSpoofingConfig,
  }) async {
    if (_disposed) throw StateError('Controller is disposed');
    _resetUser();
    _setState(FaceAuthState.cameraOpened);

    try {
      _user = await _faceAuth.loginWithCamera(
        onFaceDetected: _updateFace,
        onProgress: (data) {
          _setState(data);
          _handleAntiSpoofingState(data);
          onProgress?.call(data);
        },
        onError: (error) {
          _errorMessage = error.userMessage;
          _setState(FaceAuthState.failed);
          _clearLivenessPrompts();
          onError?.call(error);
        },
        antiSpoofingConfig: antiSpoofingConfig,
      );

      _setState(FaceAuthState.success);
      _clearLivenessPrompts();
    } catch (e) {
      // Convert error to FaceAuthError if it's not already
      final faceAuthError =
          e is FaceAuthError ? e : FaceAuthError.fromMessage(e.toString());

      _errorMessage = faceAuthError.userMessage;
      _setState(FaceAuthState.failed);
      _clearLivenessPrompts();
      onError?.call(faceAuthError);
    }

    onDone?.call(_user);
  }

  /// Update the controller state
  void _setState(FaceAuthState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  /// Handle anti-spoofing specific states and update UI accordingly
  void _handleAntiSpoofingState(FaceAuthState state) {
    if (_disposed) return;

    switch (state) {
      case FaceAuthState.antiSpoofingCheck:
        _updateLivenessPrompts(_getAntiSpoofingPrompts());
        break;
      case FaceAuthState.spoofingDetected:
        _updateLivenessPrompts([
          'Spoofing detected!',
          'Please ensure you are a real person',
          'Remove any masks or coverings',
          'Try again with good lighting'
        ]);
        break;
      case FaceAuthState.success:
      case FaceAuthState.failed:
        _clearLivenessPrompts();
        break;
      default:
        break;
    }
  }

  /// Get appropriate liveness prompts based on current anti-spoofing configuration
  List<String> _getAntiSpoofingPrompts() {
    final prompts = <String>[];

    if (_antiSpoofingConfig.requireActiveLiveness) {
      prompts.addAll([
        'Please blink naturally',
        'Move your head slightly',
        'Look directly at the camera'
      ]);
    } else {
      prompts.addAll([
        'Stay still and look at the camera',
        'Ensure good lighting',
        'Keep your face centered'
      ]);
    }

    return prompts;
  }

  /// Update detected faces
  void _updateFace(List<Face>? faces, CameraImage image) {
    if (_disposed) return;
    _faces = faces;
    _imageSize ??= previewSize;
    notifyListeners();
  }

  /// Reset user before login/register
  void _resetUser() {
    if (_disposed) return;
    _user = null;
    _faces = null;
    _errorMessage = null;
    _antiSpoofingResult = null;
    _clearLivenessPrompts();
  }

  /// Clear error message
  void clearError() {
    if (_disposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset controller state for retry
  void reset() {
    if (_disposed) return;
    _resetUser();
    _state = null;
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _disposed = true;
    _stopCameraStream();
    cameraService.cameraController?.dispose();
    _faceAuth.cameraService.dispose();
    _faceAuth.dispose();
    super.dispose();
  }

  void _stopCameraStream() {
    if (_disposed) return;
    final controller = cameraService.cameraController;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
  }

  Size get previewSize {
    if (_disposed || cameraService.cameraController == null) {
      return const Size(0, 0);
    }
    return Size(
      cameraService.cameraController!.value.previewSize!.height,
      cameraService.cameraController!.value.previewSize!.width,
    );
  }

  /// Check if a user exists by ID
  Future<bool> userExists(String userId) async {
    if (_disposed) throw StateError('Controller is disposed');
    await initializeDatabaseOnly();
    return await _faceAuth.userExists(userId);
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    if (_disposed) throw StateError('Controller is disposed');
    await initializeDatabaseOnly();
    return await _faceAuth.getUserById(userId);
  }

  /// Delete user by ID
  Future<int> deleteUser(String userId) async {
    if (_disposed) throw StateError('Controller is disposed');
    await initializeDatabaseOnly();
    return await _faceAuth.deleteUser(userId);
  }

  /// Get all registered users
  Future<List<User>> getAllUsers() async {
    if (_disposed) throw StateError('Controller is disposed');
    await initializeDatabaseOnly();
    return await _faceAuth.getAllUsers();
  }

  /// Delete all users from database
  Future<void> deleteAllUsers() async {
    if (_disposed) throw StateError('Controller is disposed');
    await initializeDatabaseOnly();
    return await _faceAuth.deleteDatabase();
  }
}
