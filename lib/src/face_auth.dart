import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

typedef FaceAuthProgress = void Function(FaceAuthState state);
typedef FaceDetectionCallback =
    void Function(List<Face>? faces, CameraImage image);

enum FaceAuthState {
  cameraOpened,
  detectingFace,
  collectingSamples,
  matching,
  success,
  failed,
  timeout,
}

/// High-level facade for common face auth operations.
class FaceAuth {
  FaceAuth();

  late CameraService _cameraService;
  late DatabaseHelper _database;
  late FaceDetectorService _faceDetectorService;
  bool _initialized = false;
  late MLService _mlService;
  bool _processing = false;
  bool _detectFaceProcessing = false;

  CameraService get cameraService => _cameraService;

  FaceDetectorService get faceDetectorService => _faceDetectorService;

  /// Initialize services
  Future<void> initialize() async {
    _mlService = MLService();
    _database = DatabaseHelper.instance;
    _cameraService = CameraService();
    _faceDetectorService = FaceDetectorService(_cameraService);
    await _mlService.initialize();
    await _cameraService.initialize();
    _faceDetectorService.initialize();
    _initialized = true;
    _initialized = true;
  }

  /// Register user via camera
  Future<User> registerWithCamera({
    int requiredSamples = 4,
    Duration timeout = const Duration(seconds: 20),
    FaceAuthProgress? onProgress,
    FaceDetectionCallback? onFaceDetected,
  }) async {
    if (!_initialized) await initialize();
    if (_processing) throw StateError('Another operation in progress');
    _processing = true;

    final List<List<num>> samples = [];
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

        _mlService.setCurrentPrediction(image, face);
        final emb = List.from(_mlService.predictedData);
        if (emb.isEmpty) return;

        samples.add(emb.cast<num>());
        onProgress?.call(FaceAuthState.collectingSamples);

        if (samples.length >= requiredSamples) {
          final centroid = _mlService.centroidFromSamples(samples);
          final predicted = await _mlService.predictFromEmbedding(centroid);
          if (predicted != null) {
            finishError(StateError("Face already registered"));

            _detectFaceProcessing = false;

            return;
          }

          int id = await _database.insert(User(modelData: samples));
          finishOk(User(modelData: samples, id: id.toString()));
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
  }) async {
    if (!_initialized) await initialize();
    if (_processing) throw StateError('Another operation in progress');
    _processing = true;

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

        finish(null, FaceAuthState.failed);
      }
      _detectFaceProcessing = false;
    });

    return completer.future;
  }

  Future<void> dispose() async {
    await _cameraService.stopImageStreamIfActive();
    _faceDetectorService.dispose();
    await _cameraService.dispose();
  }

  Future deleteDatabase() async {
    await _database.deleteAll();
  }
}
