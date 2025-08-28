import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_recognition_auth/src/db/database_helper.dart';
import 'package:face_recognition_auth/src/models/user.model.dart';
import 'package:face_recognition_auth/src/services/image_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;
  // Cosine similarity threshold (higher is more similar). Typical range: 0.5 - 0.8
  double threshold = 0.7;

  List _predictedData = [];
  List get predictedData => _predictedData;

  Future initialize() async {
    final String modelPath =
        'packages/face_recognition_auth/assets/mobilefacenet.tflite';
    // Force CPU on Android (Adreno GPU crash), allow GPU on iOS only
    try {
      if (Platform.isAndroid) {
        final cpuOptions = InterpreterOptions()
          ..threads = 2
          ..useNnApiForAndroid = false;
        _interpreter = await Interpreter.fromAsset(
          modelPath,
          options: cpuOptions,
        );
        dev.log('TFLite loaded with CPU (XNNPACK) on Android');
        return;
      }

      if (Platform.isIOS) {
        try {
          final gpu = GpuDelegate();
          final options = InterpreterOptions()..addDelegate(gpu);
          _interpreter = await Interpreter.fromAsset(
            modelPath,
            options: options,
          );
          dev.log('TFLite loaded with Metal GPU delegate');
          return;
        } catch (e) {
          dev.log('iOS GPU delegate failed, falling back to CPU. $e');
        }
      }

      final cpuOptions = InterpreterOptions()
        ..threads = 1
        ..useNnApiForAndroid = false;

      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: cpuOptions,
      );
      dev.log('TFLite loaded with CPU (fallback)');
    } catch (e) {
      dev.log('Failed to load model. $e');
    }
  }

  Future<void> initializeFromBytes(Uint8List modelBytes) async {
  try {
    if (Platform.isAndroid) {
      final cpuOptions = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;

      _interpreter = Interpreter.fromBuffer(
        modelBytes,
        options: cpuOptions,
      );
      dev.log('TFLite loaded with CPU (XNNPACK) on Android');
      return;
    }

    if (Platform.isIOS) {
      try {
        final gpu = GpuDelegate();
        final options = InterpreterOptions()..addDelegate(gpu);

        _interpreter = Interpreter.fromBuffer(
          modelBytes,
          options: options,
        );
        dev.log('TFLite loaded with Metal GPU delegate');
        return;
      } catch (e) {
        dev.log('iOS GPU delegate failed, falling back to CPU. $e');
      }
    }

    // fallback CPU
    final cpuOptions = InterpreterOptions()
      ..threads = 1
      ..useNnApiForAndroid = false;

    _interpreter = Interpreter.fromBuffer(
      modelBytes,
      options: cpuOptions,
    );
    dev.log('TFLite loaded with CPU (fallback)');
  } catch (e) {
    dev.log('Failed to load model. $e');
  }
}


  void setCurrentPrediction(CameraImage cameraImage, Face? face) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');
    List input = _preProcess(cameraImage, face);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    _interpreter?.run(input, output);
    output = output.reshape([192]);

    _predictedData = List.from(output);
  }

  void setCurrentPrediction2(imglib.Image croppedImage, Face? face) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');
    List input = _preProcess2(croppedImage, face);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    _interpreter?.run(input, output);
    output = output.reshape([192]);

    _predictedData = List.from(output);
  }

  Future<User?> predict() async {
    return _searchResult(_predictedData);
  }

  // Predict using a provided embedding instead of the current prediction
  Future<User?> predictFromEmbedding(List embedding) async {
    return _searchResult(embedding);
  }

  List _preProcess(CameraImage image, Face faceDetected) {
    imglib.Image croppedImage = _cropFace(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);

    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }
  List _preProcess2(imglib.Image croppedImage, Face faceDetected) {
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);

    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  imglib.Image _cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = _convertCameraImage(image);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(
      convertedImage,
      x: x.round(),
      y: y.round(),
      width: w.round(),
      height: h.round(),
    );
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    var img = convertToImage(image);
    var img1 = imglib.copyRotate(img, angle: -90);
    return img1;
  }

  Float32List imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        final imglib.Pixel pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - 128) / 128;
        buffer[pixelIndex++] = (pixel.g - 128) / 128;
        buffer[pixelIndex++] = (pixel.b - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  Future<User?> _searchResult(List predictedData) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    List<User> users = await dbHelper.queryAllUsers();
    double maxSim = -1.0;
    double currSim = 0.0;
    User? predictedResult;

    for (User u in users) {
      final List representative = _representativeEmbedding(u.modelData);
      currSim = _cosineSimilarity(representative, predictedData);
      if (currSim >= threshold && currSim > maxSim) {
        maxSim = currSim;
        predictedResult = u;
      }
    }
    return predictedResult;
  }

  // If user.modelData is a list of lists (multiple samples), return centroid.
  // Otherwise, return the single embedding as-is.
  List<double> _representativeEmbedding(List data) {
    if (data.isNotEmpty && data.first is List) {
      final List<List<num>> samples = data
          .cast<List>()
          .map((e) => e.cast<num>())
          .toList();
      return _centroid(samples);
    }
    return data.map((e) => (e as num).toDouble()).toList();
  }

  List<double> _centroid(List<List<num>> samples) {
    if (samples.isEmpty) return [];
    final int dim = samples.first.length;
    final List<double> sum = List<double>.filled(dim, 0.0);
    for (final List<num> s in samples) {
      for (int i = 0; i < dim; i++) {
        sum[i] += s[i].toDouble();
      }
    }
    final double n = samples.length.toDouble();
    for (int i = 0; i < dim; i++) {
      sum[i] = sum[i] / n;
    }
    return sum;
  }

  // Expose a public centroid helper for enrollment flows
  List<double> centroidFromSamples(List<List<num>> samples) {
    return _centroid(samples);
  }

  double _cosineSimilarity(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception('Null argument');

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < e1.length; i++) {
      final double a = (e1[i] as num).toDouble();
      final double b = (e2[i] as num).toDouble();
      dot += a * b;
      normA += a * a;
      normB += b * b;
    }
    final double denom = sqrt(normA) * sqrt(normB);
    if (denom == 0.0) return -1.0;
    return dot / denom;
  }

  void setPredictedData(value) {
    _predictedData = value;
  }

  dispose() {}
}
