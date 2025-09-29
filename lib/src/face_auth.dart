import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

typedef FaceAuthProgress = void Function(FaceAuthState state);
typedef FaceDetectionCallback = void Function(
    List<Face>? faces, CameraImage image);
typedef FaceAuthErrorCallback = void Function(FaceAuthError error);

enum FaceAuthState {
  cameraOpened,
  detectingFace,
  collectingSamples,
  antiSpoofingCheck,
  matching,
  success,
  failed,
  timeout,
  spoofingDetected,
}

/// High-level facade for common face auth operations.
class FaceAuth {
  FaceAuth();

  late CameraService _cameraService;
  late DatabaseHelper _database;
  late FaceDetectorService _faceDetectorService;
  late ImprovedAntiSpoofingService _antiSpoofingService;
  late MultiAngleCaptureService _multiAngleCaptureService;
  bool _initialized = false;
  bool _dbInitialized = false;
  late MLService _mlService;
  bool _processing = false;
  bool _detectFaceProcessing = false;
  AntiSpoofingConfig _antiSpoofingConfig = AntiSpoofingConfig.balanced();
  bool _useMultiAngleCapture = true;

  CameraService get cameraService => _cameraService;

  FaceDetectorService get faceDetectorService => _faceDetectorService;

  ImprovedAntiSpoofingService get antiSpoofingService => _antiSpoofingService;

  MultiAngleCaptureService get multiAngleCaptureService =>
      _multiAngleCaptureService;

  /// Configure anti-spoofing settings
  void configureAntiSpoofing(AntiSpoofingConfig config) {
    _antiSpoofingConfig = config;
  }

  /// Get current anti-spoofing configuration
  AntiSpoofingConfig get antiSpoofingConfig => _antiSpoofingConfig;

  /// Configure multi-angle capture
  void configureMultiAngleCapture(bool enabled) {
    _useMultiAngleCapture = enabled;
  }

  /// Get multi-angle capture setting
  bool get useMultiAngleCapture => _useMultiAngleCapture;

  /// Initialize services
  Future<void> initialize() async {
    _mlService = MLService();
    _database = DatabaseHelper.instance;
    _cameraService = CameraService();
    _faceDetectorService = FaceDetectorService(_cameraService);
    _antiSpoofingService = ImprovedAntiSpoofingService();
    _multiAngleCaptureService = MultiAngleCaptureService();
    await _mlService.initialize();
    await _cameraService.initialize();
    _faceDetectorService.initialize();
    _initialized = true;
  }

  /// Initialize only database without camera services
  Future<void> initializeDatabaseOnly() async {
    _database = DatabaseHelper.instance;
    // Don't initialize camera, face detector, or ML model
    // Just ensure database is ready
    await _database.database;
    _dbInitialized = true;
  }

  /// Register user via camera with enhanced multi-angle capture
  Future<User> registerWithCamera({
    int requiredSamples = 4,
    Duration timeout =
        const Duration(seconds: 30), // Increased timeout for multi-angle
    FaceAuthProgress? onProgress,
    FaceDetectionCallback? onFaceDetected,
    FaceAuthErrorCallback? onError,
    required String userId,
    AntiSpoofingConfig? antiSpoofingConfig,
    bool useMultiAngleCapture = true,
  }) async {
    if (!_initialized) await initialize();
    if (_processing) throw StateError('Another operation in progress');
    _processing = true;

    // Use provided config or default
    final config = antiSpoofingConfig ?? _antiSpoofingConfig;
    final useMultiAngle = useMultiAngleCapture && _useMultiAngleCapture;

    // Reset services
    _antiSpoofingService.reset();
    if (useMultiAngle) {
      _multiAngleCaptureService.reset();
    }

    final List<List<num>> samples = [];
    final completer = Completer<User>();
    Timer? watchdog;

    void finishError(Object error) async {
      await _cameraService.stopImageStreamIfActive();
      _processing = false;
      watchdog?.cancel();
      log("error $error");
      onProgress?.call(FaceAuthState.failed);

      // Convert error to FaceAuthError if it's not already
      final faceAuthError = error is FaceAuthError
          ? error
          : FaceAuthError.fromMessage(error.toString());

      // Call onError callback if provided
      onError?.call(faceAuthError);

      if (!completer.isCompleted) completer.completeError(faceAuthError);
    }

    void finishOk(User user) async {
      await _cameraService.stopImageStreamIfActive();
      _processing = false;
      watchdog?.cancel();
      onProgress?.call(FaceAuthState.success);
      if (!completer.isCompleted) completer.complete(user);
    }

    watchdog = Timer(timeout, () {
      finishError(TimeoutException("Registration timed out"));
      onProgress?.call(FaceAuthState.timeout);
    });

    onProgress?.call(FaceAuthState.cameraOpened);
    await _cameraService.stopImageStreamIfActive();
    await _cameraService.cameraController?.startImageStream((image) async {
      if (_detectFaceProcessing) return;
      _detectFaceProcessing = true;
      try {
        onProgress?.call(FaceAuthState.detectingFace);
        await _faceDetectorService.detectFacesFromImage(image);
        if (_faceDetectorService.faces.isEmpty) {
          onFaceDetected?.call(null, image);

          return;
        }

        final face = _faceDetectorService.faces.first;
        onFaceDetected?.call(_faceDetectorService.faces, image);

        // Perform anti-spoofing check if enabled
        if (config.enabled) {
          onProgress?.call(FaceAuthState.antiSpoofingCheck);
          final antiSpoofingResult = await _antiSpoofingService.analyzeFrame(
            image,
            face,
            requireActiveLiveness: config.requireActiveLiveness,
          );

          if (config.enableDebugLogging) {
            log('Anti-spoofing result: $antiSpoofingResult');
          }

          // Check if spoofing is detected
          if (!antiSpoofingResult.isLive &&
              antiSpoofingResult.confidence < config.minConfidenceThreshold) {
            finishError(StateError(
                'Spoofing detected. ${antiSpoofingResult.recommendations.join(' ')}'));
            _detectFaceProcessing = false;
            return;
          }

          // If we don't have enough data yet, continue collecting
          if (!antiSpoofingResult.hasEnoughData) {
            _detectFaceProcessing = false;
            return;
          }
        }

        _mlService.setCurrentPrediction(image, face);
        final emb = List.from(_mlService.predictedData);
        if (emb.isEmpty) return;

        // Handle multi-angle capture if enabled
        if (useMultiAngle) {
          try {
            final angleSamples = await _multiAngleCaptureService.startCapture(
              image: image,
              face: face,
              embedding: emb.cast<num>(),
            );

            // Convert angle samples to flat list
            for (final angleSamplesList in angleSamples.values) {
              samples.addAll(angleSamplesList);
            }
          } catch (e) {
            log('Multi-angle capture error: $e');
            // Fall back to regular capture
            samples.add(emb.cast<num>());
          }
        } else {
          samples.add(emb.cast<num>());
        }

        onProgress?.call(FaceAuthState.collectingSamples);

        // Adjust required samples based on multi-angle capture
        final adjustedRequiredSamples = useMultiAngle
            ? 12
            : requiredSamples; // 3 samples per angle * 4 angles

        if (samples.length >= adjustedRequiredSamples) {
          // Check if user ID already exists
          final userExists = await _database.userExists(userId);
          if (userExists) {
            finishError(StateError("User ID already exists: $userId"));
            _detectFaceProcessing = false;
            return;
          }

          // Check if face is already registered (by face embedding)
          final centroid = _mlService.centroidFromSamples(samples);
          final predicted = await _mlService.predictFromEmbedding(centroid);
          if (predicted != null) {
            finishError(StateError("Face already registered"));
            _detectFaceProcessing = false;
            return;
          }

          // Insert new user
          await _database.insert(User(id: userId, modelData: samples));
          finishOk(User(modelData: samples, id: userId));
        }
      } catch (e) {
        finishError(e);
      }
      _detectFaceProcessing = false;
    });

    return completer.future;
  }

  /// Login via camera
  Future<User?> loginWithCamera({
    int requiredSamples = 4,
    Duration timeout = const Duration(seconds: 15),
    FaceAuthProgress? onProgress,
    FaceDetectionCallback? onFaceDetected,
    FaceAuthErrorCallback? onError,
    AntiSpoofingConfig? antiSpoofingConfig,
  }) async {
    if (!_initialized) await initialize();
    if (_processing) throw StateError('Another operation in progress');
    _processing = true;

    // Use provided config or default
    final config = antiSpoofingConfig ?? _antiSpoofingConfig;

    // Reset anti-spoofing service
    _antiSpoofingService.reset();

    final List<List<num>> samples = [];
    final completer = Completer<User?>();
    Timer? watchdog;

    void finish(User? user, FaceAuthState state) async {
      await _cameraService.stopImageStreamIfActive();
      _processing = false;
      watchdog?.cancel();
      onProgress?.call(state);
      if (!completer.isCompleted) completer.complete(user);
    }

    watchdog = Timer(timeout, () {
      finish(null, FaceAuthState.timeout);
    });

    onProgress?.call(FaceAuthState.cameraOpened);
    await _cameraService.stopImageStreamIfActive();
    await _cameraService.cameraController?.startImageStream((image) async {
      if (_detectFaceProcessing) return;
      _detectFaceProcessing = true;

      try {
        onProgress?.call(FaceAuthState.detectingFace);

        await _faceDetectorService.detectFacesFromImage(image);
        if (_faceDetectorService.faces.isEmpty) {
          _detectFaceProcessing = false;
          onFaceDetected?.call(null, image);
          return;
        }

        final face = _faceDetectorService.faces.first;
        onFaceDetected?.call(_faceDetectorService.faces, image);

        // Perform anti-spoofing check if enabled
        if (config.enabled) {
          onProgress?.call(FaceAuthState.antiSpoofingCheck);
          final antiSpoofingResult = await _antiSpoofingService.analyzeFrame(
            image,
            face,
            requireActiveLiveness: config.requireActiveLiveness,
          );

          if (config.enableDebugLogging) {
            log('Anti-spoofing result: $antiSpoofingResult');
          }

          // Check if spoofing is detected
          if (!antiSpoofingResult.isLive &&
              antiSpoofingResult.confidence < config.minConfidenceThreshold) {
            finish(null, FaceAuthState.spoofingDetected);
            _detectFaceProcessing = false;
            return;
          }

          // If we don't have enough data yet, continue collecting
          if (!antiSpoofingResult.hasEnoughData) {
            _detectFaceProcessing = false;
            return;
          }
        }

        _mlService.setCurrentPrediction(image, face);
        final emb = List.from(_mlService.predictedData);
        if (emb.isEmpty) {
          _detectFaceProcessing = false;
          return;
        }

        samples.add(emb.cast<num>());
        onProgress?.call(FaceAuthState.collectingSamples);

        if (samples.length >= requiredSamples) {
          final centroid = _mlService.centroidFromSamples(samples);
          final user = await _mlService.predictFromEmbedding(centroid);

          if (user != null) {
            finish(user, FaceAuthState.success);
          } else {
            finish(null, FaceAuthState.failed);
          }
        }
      } catch (e) {
        log("login error $e");

        // Convert error to FaceAuthError if it's not already
        final faceAuthError =
            e is FaceAuthError ? e : FaceAuthError.fromMessage(e.toString());

        // Call onError callback if provided
        onError?.call(faceAuthError);

        finish(null, FaceAuthState.failed);
      }
      _detectFaceProcessing = false;
    });

    return completer.future;
  }

  Future<void> dispose() async {
    await _cameraService.stopImageStreamIfActive();
    _faceDetectorService.dispose();
    _antiSpoofingService.dispose();
    _multiAngleCaptureService.dispose();
    await _cameraService.dispose();
  }

  Future deleteDatabase() async {
    if (!_dbInitialized) await initializeDatabaseOnly();
    await _database.deleteAll();
  }

  /// Check if a user exists by ID
  Future<bool> userExists(String userId) async {
    if (!_dbInitialized) await initializeDatabaseOnly();
    return await _database.userExists(userId);
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    if (!_dbInitialized) await initializeDatabaseOnly();
    return await _database.getUserById(userId);
  }

  /// Delete user by ID
  Future<int> deleteUser(String userId) async {
    if (!_dbInitialized) await initializeDatabaseOnly();
    return await _database.deleteUser(userId);
  }

  /// Get all registered users
  Future<List<User>> getAllUsers() async {
    if (!_dbInitialized) await initializeDatabaseOnly();
    return await _database.queryAllUsers();
  }
}
