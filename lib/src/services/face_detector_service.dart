import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/src/services/camera_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final CameraService _cameraService;

  FaceDetectorService(this._cameraService);

  late FaceDetector _faceDetector;
  FaceDetector get faceDetector => _faceDetector;

  List<Face> _faces = [];
  List<Face> get faces => _faces;
  bool get faceDetected => _faces.isNotEmpty;

  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
  }

  Future<List<Face>> detectFacesFromImage(CameraImage image) async {
    final InputImageMetadata firebaseImageMetadata = InputImageMetadata(
      rotation:
          _cameraService.cameraRotation ?? InputImageRotation.rotation0deg,
      format: Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    // Build byte buffer. On Android, provide NV21; on iOS, use planes[0] (bgra).
    final Uint8List bytes = Platform.isAndroid
        ? _toNv21(image)
        : image.planes[0].bytes;

    InputImage firebaseVisionImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: firebaseImageMetadata,
    );

    _faces = await _faceDetector.processImage(firebaseVisionImage);
    return _faces;
  }

  Future<List<Face>> detect(CameraImage image, InputImageRotation rotation) {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final inputImageFormat = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return faceDetector.processImage(
      InputImage.fromBytes(
        bytes: Platform.isAndroid ? _toNv21(image) : image.planes[0].bytes,
        metadata: inputImageData,
      ),
    );
  }

  Uint8List _toNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // Copy Y with row stride
    final int yRowStride = yPlane.bytesPerRow;
    final Uint8List yBytes = yPlane.bytes;
    int dstIndex = 0;
    for (int row = 0; row < height; row++) {
      final int srcIndex = row * yRowStride;
      nv21.setRange(
        dstIndex,
        dstIndex + width,
        yBytes.sublist(srcIndex, srcIndex + width),
      );
      dstIndex += width;
    }

    // Interleave V and U respecting pixel/row strides
    final int uvRowStrideU = uPlane.bytesPerRow;
    final int uvRowStrideV = vPlane.bytesPerRow;
    final int uvPixelStrideU = uPlane.bytesPerPixel ?? 1;
    final int uvPixelStrideV = vPlane.bytesPerPixel ?? 1;
    final Uint8List uBytes = uPlane.bytes;
    final Uint8List vBytes = vPlane.bytes;

    int uvOffset = ySize;
    for (int row = 0; row < height / 2; row++) {
      for (int col = 0; col < width / 2; col++) {
        final int uIndex = row * uvRowStrideU + col * uvPixelStrideU;
        final int vIndex = row * uvRowStrideV + col * uvPixelStrideV;
        // NV21 = V then U
        nv21[uvOffset++] = vBytes[vIndex];
        nv21[uvOffset++] = uBytes[uIndex];
      }
    }
    return nv21;
  }

  void dispose() {
    _faceDetector.close();
  }
}
