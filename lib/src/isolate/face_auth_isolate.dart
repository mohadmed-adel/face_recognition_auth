import 'dart:async';
import 'dart:developer';

import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/isolate/frame_request.dart';
import 'package:face_recognition_auth/src/isolate/isolate_helper.dart';
import 'package:flutter/services.dart';

class FaceAuthIsolate {
  FaceAuthIsolate();

  late CameraService _cameraService;
  late DatabaseHelper _database;
  late FaceDetectorService _faceDetectorService;
  bool _initialized = false;
  final bool _dbInitialized = false;
  late IsolateHelper _isolateHelper;
  bool _processing = false;
  bool _detectFaceProcessing = false;

  CameraService get cameraService => _cameraService;

  FaceDetectorService get faceDetectorService => _faceDetectorService;

  late Uint8List modelBytes;

  int frameCount = 0;
  final int skipFrames = 14;

  /// Initialize services
  Future<void> initialize() async {
    _database = DatabaseHelper.instance;
    _cameraService = CameraService();
    _faceDetectorService = FaceDetectorService(_cameraService);
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
    required String userId,
  }) async {
    if (!_initialized) await initialize();

    //init isolate
    _isolateHelper = IsolateHelper();
    final rootToken = RootIsolateToken.instance!;

    await _isolateHelper.init(
      forRegister: true,
      interpreterBytes: modelBytes,
      rootIsolateToken: rootToken,
    );

    if (_processing) throw StateError('Another operation in progress');

    _processing = true;

    final completer = Completer<User>();
    Timer? watchdog;

    void finishError(Object error) async {
      await _cameraService.stopImageStreamIfActive();
      _processing = false;
      watchdog?.cancel();
      log("error $error");
      onProgress?.call(FaceAuthState.failed);
      if (!completer.isCompleted) completer.completeError(error);
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
      try {
        frameCount++;

        if (frameCount % skipFrames != 0) return;
        onProgress?.call(FaceAuthState.detectingFace);
        final faces = await _faceDetectorService.detectFacesFromImage(image);
        if (faces.isEmpty) {
          onFaceDetected?.call(null, image);
          return;
        } else {
          onFaceDetected?.call(faces, image);
        }

        if (_detectFaceProcessing) return;
        _detectFaceProcessing = true;

        final face = faces.first;

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
          log("mano ${res.msg}");
        } else {
          log("mano ${res.msg}");
          // finishError(StateError(res.msg ?? "Unknown error"));
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
  }) async {
    if (!_initialized) await initialize();
    _isolateHelper = IsolateHelper();
    final rootToken = RootIsolateToken.instance!;

    await _isolateHelper.init(
      forRegister: false,
      interpreterBytes: modelBytes,
      rootIsolateToken: rootToken,
    );
    if (_processing) throw StateError('Another operation in progress');
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
        onProgress?.call(FaceAuthState.detectingFace);
        final faces = await _faceDetectorService.detectFacesFromImage(image);
        if (faces.isEmpty) {
          onFaceDetected?.call(null, image);

          return;
        } else {
          onFaceDetected?.call(faces, image);
        }

        if (_detectFaceProcessing) return;
        _detectFaceProcessing = true;

        final face = faces.first;

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
