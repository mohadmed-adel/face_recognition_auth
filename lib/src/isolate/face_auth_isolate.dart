import 'dart:async';
import 'dart:developer';

import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/isolate/frame_request.dart';
import 'package:face_recognition_auth/src/isolate/isolate_helper.dart';
import 'package:face_recognition_auth/src/services/improved_anti_spoofing_service.dart';
import 'package:flutter/services.dart';

class FaceAuthIsolate {
  FaceAuthIsolate();

  late CameraService _cameraService;
  late DatabaseHelper _database;
  late FaceDetectorService _faceDetectorService;
  late ImprovedAntiSpoofingService _antiSpoofingService;
  bool _initialized = false;
  final bool _dbInitialized = false;
  late IsolateHelper _isolateHelper;
  bool _processing = false;
  bool _detectFaceProcessing = false;
  bool _errorAlreadyCalled = false;

  CameraService get cameraService => _cameraService;

  FaceDetectorService get faceDetectorService => _faceDetectorService;

  late Uint8List modelBytes;

  int frameCount = 0;
  final int skipFrames = 20; // Increased to reduce processing load

  /// Initialize services
  Future<void> initialize() async {
    _database = DatabaseHelper.instance;
    _cameraService = CameraService();
    _faceDetectorService = FaceDetectorService(_cameraService);
    _antiSpoofingService = ImprovedAntiSpoofingService();
    await _cameraService.initialize();
    _faceDetectorService.initialize();
    _initialized = true;
    final modelData = await rootBundle.load(
      'packages/face_recognition_auth/assets/mobilefacenet.tflite',
    );
    modelBytes = modelData.buffer.asUint8List();
  }

  /// Initialize only database without camera services
  Future<void> initializeDatabaseOnly() async {
    _database = DatabaseHelper.instance;
    // Don't initialize camera, face detector, or ML model
    // Just ensure database is ready
    await _database.database;
  }

  /// Register user via camera
  Future<User> registerWithCamera({
    int requiredSamples = 4,
    Duration timeout = const Duration(seconds: 20),
    FaceAuthProgress? onProgress,
    FaceDetectionCallback? onFaceDetected,
    FaceAuthErrorCallback? onError,
    required String userId,
    AntiSpoofingConfig? antiSpoofingConfig,
  }) async {
    if (!_initialized) await initialize();
    _errorAlreadyCalled = false; // Reset error flag for new registration

    //init isolate
    _isolateHelper = IsolateHelper();
    final rootToken = RootIsolateToken.instance!;

    await _isolateHelper.init(
      forRegister: true,
      interpreterBytes: modelBytes,
      rootIsolateToken: rootToken,
    );

    if (_processing) {
      throw FaceAuthError.fromType(FaceAuthErrorType.operationInProgress);
    }

    _processing = true;

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
      finishError(
          FaceAuthError.fromType(FaceAuthErrorType.registrationTimeout));
      onProgress?.call(FaceAuthState.timeout);
    });

    onProgress?.call(FaceAuthState.cameraOpened);
    await _cameraService.stopImageStreamIfActive();
    await _cameraService.cameraController?.startImageStream((image) async {
      try {
        frameCount++;

        if (frameCount % skipFrames != 0) return;

        // Additional check to prevent processing if already busy (buffer overflow prevention)
        if (_detectFaceProcessing) return;

        onProgress?.call(FaceAuthState.detectingFace);
        final faces = await _faceDetectorService.detectFacesFromImage(image);
        if (faces.isEmpty) {
          onFaceDetected?.call(null, image);
          return;
        } else {
          onFaceDetected?.call(faces, image);
        }
        _detectFaceProcessing = true;

        final face = faces.first;

        // Use default anti-spoofing config if not provided
        final config =
            antiSpoofingConfig ?? AntiSpoofingConfig.handShakeResistant();

        // Perform anti-spoofing check if enabled
        if (config.enabled && !_errorAlreadyCalled) {
          onProgress?.call(FaceAuthState.antiSpoofingCheck);
          final antiSpoofingResult = await _antiSpoofingService.analyzeFrame(
            image,
            face,
            requireActiveLiveness: config.requireActiveLiveness,
          );

          if (config.enableDebugLogging) {
            log('Anti-spoofing result: $antiSpoofingResult');
          }

          // Only check for spoofing if we have enough data and high confidence in spoofing
          if (antiSpoofingResult.hasEnoughData &&
              !antiSpoofingResult.isLive &&
              antiSpoofingResult.confidence > config.minConfidenceThreshold) {
            // Determine specific spoofing type
            FaceAuthErrorType spoofingType = FaceAuthErrorType.spoofingDetected;
            if (antiSpoofingResult.recommendations
                .any((r) => r.toLowerCase().contains('photo'))) {
              spoofingType = FaceAuthErrorType.photoAttackDetected;
            } else if (antiSpoofingResult.recommendations
                .any((r) => r.toLowerCase().contains('screen'))) {
              spoofingType = FaceAuthErrorType.screenAttackDetected;
            } else if (antiSpoofingResult.recommendations
                .any((r) => r.toLowerCase().contains('liveness'))) {
              spoofingType = FaceAuthErrorType.insufficientLivenessData;
            }

            _errorAlreadyCalled = true;
            finishError(FaceAuthError.fromType(spoofingType,
                details: antiSpoofingResult.recommendations.join(' ')));
            _detectFaceProcessing = false;
            return;
          }

          // If we don't have enough data yet, continue collecting
          if (!antiSpoofingResult.hasEnoughData) {
            _detectFaceProcessing = false;
            return;
          }
        }

        if (!_cameraService.cameraController!.value.isStreamingImages) return;
        final FrameResponse res = await _isolateHelper.sendAndWait(
          FrameRequest(
            image: image,
            face: face,
            requiredSamples: requiredSamples,
            userId: userId,
          ),
        );
        if (!_cameraService.cameraController!.value.isStreamingImages) return;

        if (res.success) {
          finishOk(res.user!);
          log("success ${res.msg}");
        } else {
          // Check if this is just a sample collection progress message
          if (res.msg?.contains('Collecting samples:') == true) {
            // This is just progress, not an error - continue collecting samples
            log("Collecting samples: ${res.msg}");
            onProgress?.call(FaceAuthState.collectingSamples);
          } else if (res.msg?.contains('Face already registered') == true) {
            // Face already exists - this is a real error with more specific message
            finishError(FaceAuthError.fromMessage(
                res.msg ?? 'Face already registered'));
          } else if (res.msg?.contains('User ID already exists') == true) {
            // User ID already exists - this is a real error
            finishError(
                FaceAuthError.fromMessage(res.msg ?? 'User ID already exists'));
          } else if (res.msg?.contains('No face detected') == true) {
            // No face detected - this is normal during face detection, not an error
            log("No face detected: ${res.msg}");
            // Continue processing, don't call finishError
          } else {
            // Other errors
            log("error ${res.msg}");
            finishError(FaceAuthError.fromMessage(res.msg ?? 'Unknown error'));
          }
        }
      } catch (e) {
        finishError(e);
      } finally {
        _detectFaceProcessing = false;
      }
    });

    return completer.future;
  }

  /// Login via camera
  Future<User?> loginWithCamera({
    Duration timeout = const Duration(seconds: 15),
    FaceAuthProgress? onProgress,
    FaceDetectionCallback? onFaceDetected,
    FaceAuthErrorCallback? onError,
    AntiSpoofingConfig? antiSpoofingConfig,
  }) async {
    if (!_initialized) await initialize();
    _errorAlreadyCalled = false; // Reset error flag for new login
    _isolateHelper = IsolateHelper();
    final rootToken = RootIsolateToken.instance!;

    await _isolateHelper.init(
      forRegister: false,
      interpreterBytes: modelBytes,
      rootIsolateToken: rootToken,
    );
    if (_processing) {
      throw FaceAuthError.fromType(FaceAuthErrorType.operationInProgress);
    }
    _processing = true;

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
      try {
        frameCount++;

        if (frameCount % skipFrames != 0) return;

        // Additional check to prevent processing if already busy (buffer overflow prevention)
        if (_detectFaceProcessing) return;

        onProgress?.call(FaceAuthState.detectingFace);
        final faces = await _faceDetectorService.detectFacesFromImage(image);
        if (faces.isEmpty) {
          onFaceDetected?.call(null, image);

          return;
        } else {
          onFaceDetected?.call(faces, image);
        }
        _detectFaceProcessing = true;

        final face = faces.first;

        // Use default anti-spoofing config if not provided
        final config =
            antiSpoofingConfig ?? AntiSpoofingConfig.handShakeResistant();

        // Perform anti-spoofing check if enabled
        if (config.enabled && !_errorAlreadyCalled) {
          onProgress?.call(FaceAuthState.antiSpoofingCheck);
          final antiSpoofingResult = await _antiSpoofingService.analyzeFrame(
            image,
            face,
            requireActiveLiveness: config.requireActiveLiveness,
          );

          if (config.enableDebugLogging) {
            log('Anti-spoofing result: $antiSpoofingResult');
          }

          // Only check for spoofing if we have enough data and high confidence in spoofing
          if (antiSpoofingResult.hasEnoughData &&
              !antiSpoofingResult.isLive &&
              antiSpoofingResult.confidence > config.minConfidenceThreshold) {
            // Determine specific spoofing type
            FaceAuthErrorType spoofingType = FaceAuthErrorType.spoofingDetected;
            if (antiSpoofingResult.recommendations
                .any((r) => r.toLowerCase().contains('photo'))) {
              spoofingType = FaceAuthErrorType.photoAttackDetected;
            } else if (antiSpoofingResult.recommendations
                .any((r) => r.toLowerCase().contains('screen'))) {
              spoofingType = FaceAuthErrorType.screenAttackDetected;
            } else if (antiSpoofingResult.recommendations
                .any((r) => r.toLowerCase().contains('liveness'))) {
              spoofingType = FaceAuthErrorType.insufficientLivenessData;
            }

            _errorAlreadyCalled = true;
            // Call onError callback if provided
            onError?.call(FaceAuthError.fromType(spoofingType,
                details: antiSpoofingResult.recommendations.join(' ')));
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

        final FrameResponse res = await _isolateHelper.sendAndWait(
          FrameRequest(image: image, face: face, requiredSamples: 1),
        );

        if (res.success) {
          finish(res.user, FaceAuthState.success);
          log("mano ${res.msg}");
        } else {
          log("mano ${res.msg}");

          // finish(null, FaceAuthState.failed);
        }
      } catch (e) {
        // Convert error to FaceAuthError if it's not already
        final faceAuthError =
            e is FaceAuthError ? e : FaceAuthError.fromMessage(e.toString());

        // Call onError callback if provided
        onError?.call(faceAuthError);

        finish(null, FaceAuthState.failed);
      } finally {
        _detectFaceProcessing = false;
      }
      _detectFaceProcessing = false;
    });

    return completer.future;
  }

  Future<void> dispose() async {
    _isolateHelper.dispose();
    await _cameraService.stopImageStreamIfActive();
    _faceDetectorService.dispose();
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
