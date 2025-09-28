import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;

/// Anti-spoofing detection service that provides multiple layers of liveness detection
class AntiSpoofingService {
  // Configuration parameters
  static const double _motionThreshold = 0.3;
  static const int _minFramesForAnalysis = 10;
  static const int _maxFramesForAnalysis = 30;

  // State tracking
  final List<CameraImage> _frameBuffer = [];
  final List<Face> _faceBuffer = [];
  final List<double> _textureScores = [];
  final List<double> _motionScores = [];
  final List<bool> _blinkDetections = [];

  DateTime? _lastBlinkTime;

  /// Analyze a single frame for anti-spoofing indicators
  Future<AntiSpoofingResult> analyzeFrame(
    CameraImage image,
    Face face, {
    bool requireActiveLiveness = false,
  }) async {
    // Add frame to buffer
    _frameBuffer.add(image);
    _faceBuffer.add(face);

    // Keep buffer size manageable
    if (_frameBuffer.length > _maxFramesForAnalysis) {
      _frameBuffer.removeAt(0);
      _faceBuffer.removeAt(0);
    }

    // Perform real-time analysis
    final textureScore = await _analyzeTexture(image, face);
    final motionScore = await _analyzeMotion();
    final blinkDetected = await _detectBlink(face);

    _textureScores.add(textureScore);
    _motionScores.add(motionScore);
    _blinkDetections.add(blinkDetected);

    // Keep score buffers manageable
    if (_textureScores.length > _maxFramesForAnalysis) {
      _textureScores.removeAt(0);
      _motionScores.removeAt(0);
      _blinkDetections.removeAt(0);
    }

    // Calculate overall liveness score
    final livenessScore = _calculateLivenessScore();

    // Determine if we have enough data for a decision
    final hasEnoughData = _frameBuffer.length >= _minFramesForAnalysis;

    // Check for active liveness requirements
    final activeLivenessPassed =
        requireActiveLiveness ? _checkActiveLiveness() : true;

    return AntiSpoofingResult(
      isLive: hasEnoughData && livenessScore > 0.5 && activeLivenessPassed,
      confidence: livenessScore,
      textureScore: textureScore,
      motionScore: motionScore,
      blinkDetected: blinkDetected,
      hasEnoughData: hasEnoughData,
      activeLivenessPassed: activeLivenessPassed,
      recommendations: _getRecommendations(livenessScore, activeLivenessPassed),
    );
  }

  /// Analyze texture patterns to detect spoofing
  Future<double> _analyzeTexture(CameraImage image, Face face) async {
    try {
      // Convert camera image to processable format
      final croppedImage = _cropFaceFromCameraImage(image, face);
      final resizedImage =
          imglib.copyResize(croppedImage, width: 64, height: 64);

      // Calculate Local Binary Pattern (LBP) features
      final lbpScore = _calculateLBP(resizedImage);

      // Calculate texture variance
      final varianceScore = _calculateTextureVariance(resizedImage);

      // Calculate edge density
      final edgeScore = _calculateEdgeDensity(resizedImage);

      // Combine scores (higher is more likely to be live)
      final combinedScore =
          (lbpScore * 0.4 + varianceScore * 0.3 + edgeScore * 0.3);

      return combinedScore.clamp(0.0, 1.0);
    } catch (e) {
      dev.log('Texture analysis error: $e');
      return 0.5; // Neutral score on error
    }
  }

  /// Analyze motion patterns between frames
  Future<double> _analyzeMotion() async {
    if (_frameBuffer.length < 2) return 0.5;

    try {
      final currentFrame = _frameBuffer.last;
      final previousFrame = _frameBuffer[_frameBuffer.length - 2];

      // Calculate optical flow or frame difference
      final motionScore =
          _calculateFrameDifference(currentFrame, previousFrame);

      return motionScore.clamp(0.0, 1.0);
    } catch (e) {
      dev.log('Motion analysis error: $e');
      return 0.5;
    }
  }

  /// Detect eye blinks using Eye Aspect Ratio (EAR)
  Future<bool> _detectBlink(Face face) async {
    try {
      if (face.landmarks.isEmpty) return false;

      // Get eye landmarks - simplified approach since we don't have access to positions
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];

      if (leftEye == null || rightEye == null) return false;

      // For now, use a simplified blink detection based on face bounding box changes
      // In a real implementation, you'd need access to the actual landmark positions
      final currentArea = face.boundingBox.width * face.boundingBox.height;

      if (_faceBuffer.length >= 2) {
        final previousFace = _faceBuffer[_faceBuffer.length - 2];
        final previousArea =
            previousFace.boundingBox.width * previousFace.boundingBox.height;

        // Detect significant area change (potential blink)
        final areaChange = (currentArea - previousArea).abs() / previousArea;
        return areaChange > 0.1; // 10% area change threshold
      }

      return false;
    } catch (e) {
      dev.log('Blink detection error: $e');
      return false;
    }
  }

  /// Calculate Local Binary Pattern score
  double _calculateLBP(imglib.Image image) {
    // Simplified LBP calculation
    int lbpCount = 0;
    int totalPixels = 0;

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final center = image.getPixel(x, y).luminance;
        int lbp = 0;

        // Check 8 neighbors
        final neighbors = [
          image.getPixel(x - 1, y - 1).luminance,
          image.getPixel(x, y - 1).luminance,
          image.getPixel(x + 1, y - 1).luminance,
          image.getPixel(x + 1, y).luminance,
          image.getPixel(x + 1, y + 1).luminance,
          image.getPixel(x, y + 1).luminance,
          image.getPixel(x - 1, y + 1).luminance,
          image.getPixel(x - 1, y).luminance,
        ];

        for (int i = 0; i < 8; i++) {
          if (neighbors[i] >= center) {
            lbp |= (1 << i);
          }
        }

        // Count non-uniform patterns (more texture = more likely live)
        if (_isUniformLBP(lbp)) {
          lbpCount++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? lbpCount / totalPixels : 0.0;
  }

  /// Check if LBP pattern is uniform
  bool _isUniformLBP(int lbp) {
    int transitions = 0;
    int prev = lbp & 1;

    for (int i = 1; i <= 8; i++) {
      int current = (lbp >> i) & 1;
      if (current != prev) {
        transitions++;
      }
      prev = current;
    }

    return transitions <= 2;
  }

  /// Calculate texture variance
  double _calculateTextureVariance(imglib.Image image) {
    // Convert to grayscale and calculate variance
    final pixels = <int>[];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        pixels.add(image.getPixel(x, y).luminance.toInt());
      }
    }

    if (pixels.isEmpty) return 0.0;

    final mean = pixels.reduce((a, b) => a + b) / pixels.length;
    final variance =
        pixels.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) /
            pixels.length;

    // Normalize variance (higher variance = more texture = more likely live)
    return (variance / 10000).clamp(0.0, 1.0);
  }

  /// Calculate edge density
  double _calculateEdgeDensity(imglib.Image image) {
    // Simplified edge detection using Sobel operator
    int edgeCount = 0;
    int totalPixels = 0;

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final gx = _sobelX(image, x, y);
        final gy = _sobelY(image, x, y);
        final magnitude = sqrt(gx * gx + gy * gy);

        if (magnitude > 30) {
          // Threshold for edge detection
          edgeCount++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? edgeCount / totalPixels : 0.0;
  }

  /// Sobel X operator
  double _sobelX(imglib.Image image, int x, int y) {
    final topLeft = image.getPixel(x - 1, y - 1).luminance;
    final topRight = image.getPixel(x + 1, y - 1).luminance;
    final bottomLeft = image.getPixel(x - 1, y + 1).luminance;
    final bottomRight = image.getPixel(x + 1, y + 1).luminance;

    return (-topLeft +
            topRight -
            2 * bottomLeft +
            2 * bottomRight -
            bottomLeft +
            bottomRight) /
        4.0;
  }

  /// Sobel Y operator
  double _sobelY(imglib.Image image, int x, int y) {
    final topLeft = image.getPixel(x - 1, y - 1).luminance;
    final top = image.getPixel(x, y - 1).luminance;
    final topRight = image.getPixel(x + 1, y - 1).luminance;
    final bottomLeft = image.getPixel(x - 1, y + 1).luminance;
    final bottom = image.getPixel(x, y + 1).luminance;
    final bottomRight = image.getPixel(x + 1, y + 1).luminance;

    return (-topLeft -
            2 * top -
            topRight +
            bottomLeft +
            2 * bottom +
            bottomRight) /
        4.0;
  }

  /// Calculate frame difference for motion detection
  double _calculateFrameDifference(CameraImage frame1, CameraImage frame2) {
    // Simplified frame difference calculation
    // In a real implementation, you'd want to align faces first

    if (frame1.planes.length != frame2.planes.length) return 0.0;

    int differences = 0;
    int totalPixels = 0;

    for (int plane = 0; plane < frame1.planes.length; plane++) {
      final bytes1 = frame1.planes[plane].bytes;
      final bytes2 = frame2.planes[plane].bytes;

      final minLength = min(bytes1.length, bytes2.length);

      for (int i = 0; i < minLength; i += 4) {
        // Sample every 4th pixel for performance
        if ((bytes1[i] - bytes2[i]).abs() > 10) {
          differences++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? differences / totalPixels : 0.0;
  }

  /// Crop face from camera image
  imglib.Image _cropFaceFromCameraImage(CameraImage image, Face face) {
    // Convert camera image to processable format
    final convertedImage = _convertCameraImage(image);

    // Crop face region with some padding
    final x = (face.boundingBox.left - 10).clamp(0, convertedImage.width - 1);
    final y = (face.boundingBox.top - 10).clamp(0, convertedImage.height - 1);
    final width =
        (face.boundingBox.width + 20).clamp(1, convertedImage.width - x);
    final height =
        (face.boundingBox.height + 20).clamp(1, convertedImage.height - y);

    return imglib.copyCrop(
      convertedImage,
      x: x.round(),
      y: y.round(),
      width: width.round(),
      height: height.round(),
    );
  }

  /// Convert camera image to processable format
  imglib.Image _convertCameraImage(CameraImage image) {
    // This is a simplified conversion - you might want to use your existing image converter
    final width = image.width;
    final height = image.height;

    // Create a new image
    final img = imglib.Image(width: width, height: height);

    // Convert YUV to RGB (simplified)
    final yPlane = image.planes[0].bytes;
    final uPlane =
        image.planes.length > 1 ? image.planes[1].bytes : Uint8List(0);
    final vPlane =
        image.planes.length > 2 ? image.planes[2].bytes : Uint8List(0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final yValue = yPlane[yIndex];
        final uValue = uPlane.isNotEmpty ? uPlane[uvIndex] : 128;
        final vValue = vPlane.isNotEmpty ? vPlane[uvIndex] : 128;

        // Convert YUV to RGB
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        img.setPixel(x, y, imglib.ColorRgb8(r, g, b));
      }
    }

    return img;
  }

  /// Calculate overall liveness score
  double _calculateLivenessScore() {
    if (_textureScores.isEmpty || _motionScores.isEmpty) return 0.5;

    // Calculate average scores
    final avgTexture =
        _textureScores.reduce((a, b) => a + b) / _textureScores.length;
    final avgMotion =
        _motionScores.reduce((a, b) => a + b) / _motionScores.length;

    // Weight the scores (texture is more important for static spoofing)
    final livenessScore = (avgTexture * 0.6 + avgMotion * 0.4);

    return livenessScore.clamp(0.0, 1.0);
  }

  /// Check active liveness requirements
  bool _checkActiveLiveness() {
    // Check if we've detected a blink recently (within last 5 seconds)
    if (_lastBlinkTime != null) {
      final timeSinceBlink = DateTime.now().difference(_lastBlinkTime!);
      if (timeSinceBlink.inSeconds < 5) {
        return true;
      }
    }

    // Check if we have sufficient motion
    if (_motionScores.isNotEmpty) {
      final avgMotion =
          _motionScores.reduce((a, b) => a + b) / _motionScores.length;
      return avgMotion > _motionThreshold;
    }

    return false;
  }

  /// Get recommendations based on analysis
  List<String> _getRecommendations(
      double livenessScore, bool activeLivenessPassed) {
    final recommendations = <String>[];

    if (livenessScore < 0.3) {
      recommendations.add('Please ensure good lighting');
      recommendations.add('Remove any masks or coverings');
      recommendations.add('Look directly at the camera');
    } else if (livenessScore < 0.5) {
      recommendations.add('Try moving slightly');
      recommendations.add('Blink naturally');
    }

    if (!activeLivenessPassed) {
      recommendations.add('Please blink or move your head slightly');
    }

    return recommendations;
  }

  /// Reset the service state
  void reset() {
    _frameBuffer.clear();
    _faceBuffer.clear();
    _textureScores.clear();
    _motionScores.clear();
    _blinkDetections.clear();
    _lastBlinkTime = null;
  }

  /// Dispose resources
  void dispose() {
    reset();
  }
}

/// Result of anti-spoofing analysis
class AntiSpoofingResult {
  final bool isLive;
  final double confidence;
  final double textureScore;
  final double motionScore;
  final bool blinkDetected;
  final bool hasEnoughData;
  final bool activeLivenessPassed;
  final List<String> recommendations;

  const AntiSpoofingResult({
    required this.isLive,
    required this.confidence,
    required this.textureScore,
    required this.motionScore,
    required this.blinkDetected,
    required this.hasEnoughData,
    required this.activeLivenessPassed,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'AntiSpoofingResult(isLive: $isLive, confidence: $confidence, '
        'textureScore: $textureScore, motionScore: $motionScore, '
        'blinkDetected: $blinkDetected, hasEnoughData: $hasEnoughData, '
        'activeLivenessPassed: $activeLivenessPassed)';
  }
}
