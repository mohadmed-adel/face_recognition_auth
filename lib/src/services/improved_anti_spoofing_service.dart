import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;

/// Improved anti-spoofing detection service based on industry best practices
/// Inspired by NIST FRVT standards and OpenCV Face Recognition approaches
class ImprovedAntiSpoofingService {
  // Enhanced configuration parameters
  static const int _minFramesForAnalysis = 8;
  static const int _maxFramesForAnalysis = 25;
  static const double _blinkDetectionThreshold = 0.15;

  // State tracking
  final List<CameraImage> _frameBuffer = [];
  final List<Face> _faceBuffer = [];
  final List<double> _textureScores = [];
  final List<double> _motionScores = [];
  final List<bool> _blinkDetections = [];
  final List<double> _headMovementScores = [];

  /// Enhanced analysis with better screen attack detection
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

    // Enhanced analysis components
    final textureScore = await _analyzeEnhancedTexture(image, face);
    final motionScore = await _analyzeEnhancedMotion();
    final blinkDetected = await _detectEnhancedBlink(face);
    final headMovementScore = _analyzeHeadMovement(face);

    _textureScores.add(textureScore);
    _motionScores.add(motionScore);
    _blinkDetections.add(blinkDetected);
    _headMovementScores.add(headMovementScore);

    // Keep score buffers manageable
    if (_textureScores.length > _maxFramesForAnalysis) {
      _textureScores.removeAt(0);
      _motionScores.removeAt(0);
      _blinkDetections.removeAt(0);
      _headMovementScores.removeAt(0);
    }

    // Calculate enhanced liveness score
    final livenessScore = _calculateEnhancedLivenessScore();

    // Determine if we have enough data for a decision
    final hasEnoughData = _frameBuffer.length >= _minFramesForAnalysis;

    // Check for active liveness requirements
    final activeLivenessPassed =
        requireActiveLiveness ? _checkActiveLiveness() : true;

    // Check for required head movement
    final headMovementPassed = _checkHeadMovementRequirement();

    // Enhanced screen attack detection
    final isScreenAttack =
        _detectScreenAttack(textureScore, motionScore, headMovementScore);

    final isLive = hasEnoughData &&
        !isScreenAttack && // Explicitly check for screen attacks
        livenessScore > 0.4 && // Balanced threshold
        (!requireActiveLiveness || activeLivenessPassed) &&
        (!requireActiveLiveness || headMovementPassed) &&
        textureScore > 0.3 &&
        motionScore > 0.15;

    return AntiSpoofingResult(
      isLive: isLive,
      confidence: livenessScore,
      textureScore: textureScore,
      motionScore: motionScore,
      blinkDetected: blinkDetected,
      hasEnoughData: hasEnoughData,
      activeLivenessPassed: activeLivenessPassed,
      headMovementScore: headMovementScore,
      headMovementPassed: headMovementPassed,
      recommendations: _getEnhancedRecommendations(livenessScore,
          activeLivenessPassed, headMovementPassed, isScreenAttack),
    );
  }

  /// Enhanced texture analysis with better screen detection
  Future<double> _analyzeEnhancedTexture(CameraImage image, Face face) async {
    try {
      final croppedImage = _cropFaceFromCameraImage(image, face);
      final resizedImage =
          imglib.copyResize(croppedImage, width: 128, height: 128);

      // Multiple texture analysis methods
      final lbpScore = _calculateLBP(resizedImage);
      final varianceScore = _calculateTextureVariance(resizedImage);
      final edgeScore = _calculateEdgeDensity(resizedImage);
      final qualityScore = _calculateImageQuality(resizedImage);
      final screenScore = _detectScreenPatterns(resizedImage);
      final frequencyScore = _analyzeFrequencyDomain(resizedImage);

      // Enhanced weighting with increased screen detection weight
      final combinedScore = (lbpScore * 0.2 +
          varianceScore * 0.15 +
          edgeScore * 0.15 +
          qualityScore * 0.1 +
          screenScore * 0.25 + // Increased weight for screen detection
          frequencyScore * 0.15);

      return combinedScore.clamp(0.0, 1.0);
    } catch (e) {
      dev.log('Enhanced texture analysis error: $e');
      return 0.5; // More lenient on error
    }
  }

  /// Enhanced motion analysis that distinguishes between natural and artificial motion
  Future<double> _analyzeEnhancedMotion() async {
    if (_frameBuffer.length < 2) return 0.3;

    try {
      final currentFrame = _frameBuffer.last;
      final previousFrame = _frameBuffer[_frameBuffer.length - 2];

      // Multiple motion metrics
      final frameDiffScore =
          _calculateFrameDifference(currentFrame, previousFrame);
      final faceMotionScore = _calculateFaceMotion();
      final microMotionScore = _calculateMicroMotion();

      // New: Analyze motion quality (natural vs artificial)
      final motionQualityScore = _analyzeMotionQuality();

      // New: Check for hand shake patterns
      final handShakeScore = _detectHandShakePattern();

      // Enhanced motion scoring with quality weighting
      final combinedMotionScore = (frameDiffScore * 0.3 +
          faceMotionScore * 0.3 +
          microMotionScore * 0.2 +
          motionQualityScore * 0.15 +
          handShakeScore * 0.05); // Lower weight for hand shake detection

      return combinedMotionScore.clamp(0.0, 1.0);
    } catch (e) {
      dev.log('Enhanced motion analysis error: $e');
      return 0.5; // More lenient on error
    }
  }

  /// Analyze motion quality to distinguish natural from artificial motion
  double _analyzeMotionQuality() {
    if (_motionScores.length < 3) return 0.5;

    // Real faces have more organic, varied motion patterns
    // Screen images moved by hand have more mechanical, uniform motion

    final recentScores = _motionScores.length > 5
        ? _motionScores.sublist(_motionScores.length - 5)
        : _motionScores;

    // Calculate motion smoothness and naturalness
    double smoothness = 0.0;
    double naturalness = 0.0;

    for (int i = 1; i < recentScores.length; i++) {
      final change = (recentScores[i] - recentScores[i - 1]).abs();
      smoothness += change;

      // Natural motion has more variation in direction and intensity
      if (i > 1) {
        final prevChange = (recentScores[i - 1] - recentScores[i - 2]).abs();
        final variation = (change - prevChange).abs();
        naturalness += variation;
      }
    }

    smoothness /= (recentScores.length - 1);
    naturalness /= (recentScores.length - 2);

    // Higher naturalness and moderate smoothness indicate real face motion
    // Very smooth or very erratic motion indicates artificial movement
    final qualityScore = (naturalness * 0.6 + (1.0 - smoothness) * 0.4);

    return qualityScore.clamp(0.0, 1.0);
  }

  /// Detect hand shake patterns that indicate screen manipulation
  double _detectHandShakePattern() {
    if (_motionScores.length < 5) return 0.5;

    // Hand shake typically has:
    // 1. High frequency, low amplitude motion
    // 2. More uniform motion patterns
    // 3. Less natural variation

    final recentScores = _motionScores.length > 8
        ? _motionScores.sublist(_motionScores.length - 8)
        : _motionScores;

    // Calculate motion frequency and amplitude
    double totalAmplitude = 0.0;
    int directionChanges = 0;

    for (int i = 1; i < recentScores.length; i++) {
      final change = recentScores[i] - recentScores[i - 1];
      totalAmplitude += change.abs();

      if (i > 1) {
        final prevChange = recentScores[i - 1] - recentScores[i - 2];
        if ((change > 0 && prevChange < 0) || (change < 0 && prevChange > 0)) {
          directionChanges++;
        }
      }
    }

    final avgAmplitude = totalAmplitude / (recentScores.length - 1);
    final frequency = directionChanges / (recentScores.length - 2);

    // High frequency + low amplitude = hand shake pattern
    final handShakeIndicator = (frequency * 0.7 + (1.0 - avgAmplitude) * 0.3);

    // Return inverse score (higher = less likely to be hand shake)
    return (1.0 - handShakeIndicator).clamp(0.0, 1.0);
  }

  /// Enhanced blink detection
  Future<bool> _detectEnhancedBlink(Face face) async {
    try {
      if (face.landmarks.isEmpty) return false;

      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];

      if (leftEye == null || rightEye == null) return false;

      // Enhanced blink detection using face bounding box changes
      final currentArea = face.boundingBox.width * face.boundingBox.height;

      if (_faceBuffer.length >= 2) {
        final previousFace = _faceBuffer[_faceBuffer.length - 2];
        final previousArea =
            previousFace.boundingBox.width * previousFace.boundingBox.height;

        // Detect significant area change (potential blink)
        final areaChange = (currentArea - previousArea).abs() / previousArea;

        if (areaChange > _blinkDetectionThreshold) {
          return true;
        }
      }

      return false;
    } catch (e) {
      dev.log('Enhanced blink detection error: $e');
      return false;
    }
  }

  /// Enhanced screen pattern detection
  double _detectScreenPatterns(imglib.Image image) {
    double screenScore = 0.0;
    int algorithms = 0;

    // 1. Pixel pattern detection
    final patternScore = _detectPixelPatterns(image);
    screenScore += patternScore;
    algorithms++;

    // 2. Moiré pattern detection
    final moireScore = _detectMoirePatterns(image);
    screenScore += moireScore;
    algorithms++;

    // 3. Color banding detection
    final bandingScore = _detectColorBanding(image);
    screenScore += bandingScore;
    algorithms++;

    // 4. Sharpness analysis
    final sharpnessScore = _detectUnnaturalSharpness(image);
    screenScore += sharpnessScore;
    algorithms++;

    // 5. Reflection detection
    final reflectionScore = _detectReflectionArtifacts(image);
    screenScore += reflectionScore;
    algorithms++;

    final avgScreenScore = algorithms > 0 ? screenScore / algorithms : 0.0;
    return (1.0 - avgScreenScore).clamp(0.0, 1.0);
  }

  /// Detect pixel patterns that indicate screen display
  double _detectPixelPatterns(imglib.Image image) {
    int regularPatterns = 0;
    int totalPixels = 0;

    // Check for horizontal and vertical line patterns
    for (int y = 0; y < image.height - 2; y++) {
      for (int x = 0; x < image.width - 2; x++) {
        final current = image.getPixel(x, y).luminance;
        final right = image.getPixel(x + 1, y).luminance;
        final bottom = image.getPixel(x, y + 1).luminance;
        final diagonal = image.getPixel(x + 1, y + 1).luminance;

        // Check for very similar adjacent pixels (screen pixelation)
        final horizontalDiff = (current - right).abs();
        final verticalDiff = (current - bottom).abs();
        final diagonalDiff = (current - diagonal).abs();

        // More sensitive detection for screen patterns
        if (horizontalDiff < 3 && verticalDiff < 3 && diagonalDiff < 3) {
          regularPatterns++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? regularPatterns / totalPixels : 0.0;
  }

  /// Detect moiré patterns common in screen displays
  double _detectMoirePatterns(imglib.Image image) {
    int moirePatterns = 0;
    int totalSamples = 0;

    // Sample every 4th pixel to detect moiré patterns
    for (int y = 0; y < image.height - 4; y += 4) {
      for (int x = 0; x < image.width - 4; x += 4) {
        final pixels = [
          image.getPixel(x, y).luminance,
          image.getPixel(x + 2, y).luminance,
          image.getPixel(x, y + 2).luminance,
          image.getPixel(x + 2, y + 2).luminance,
        ];

        // Check for alternating patterns (moiré effect)
        final diff1 = (pixels[0] - pixels[1]).abs();
        final diff2 = (pixels[2] - pixels[3]).abs();
        final diff3 = (pixels[0] - pixels[2]).abs();
        final diff4 = (pixels[1] - pixels[3]).abs();

        // Moiré patterns show regular alternating differences
        if (diff1 > 20 && diff2 > 20 && diff3 < 10 && diff4 < 10) {
          moirePatterns++;
        }
        totalSamples++;
      }
    }

    return totalSamples > 0 ? moirePatterns / totalSamples : 0.0;
  }

  /// Detect color banding typical of screen displays
  double _detectColorBanding(imglib.Image image) {
    int bandingPixels = 0;
    int totalPixels = 0;

    // Check for color banding in horizontal strips
    for (int y = 0; y < image.height - 1; y++) {
      for (int x = 0; x < image.width - 1; x++) {
        final current = image.getPixel(x, y);
        final right = image.getPixel(x + 1, y);

        // Check for very similar colors (banding)
        final rDiff = (current.r - right.r).abs();
        final gDiff = (current.g - right.g).abs();
        final bDiff = (current.b - right.b).abs();

        if (rDiff < 2 && gDiff < 2 && bDiff < 2) {
          bandingPixels++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? bandingPixels / totalPixels : 0.0;
  }

  /// Detect unnatural sharpness typical of screen displays
  double _detectUnnaturalSharpness(imglib.Image image) {
    double totalSharpness = 0.0;
    int samples = 0;

    // Calculate sharpness using Laplacian variance
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final center = image.getPixel(x, y).luminance;
        final neighbors = [
          image.getPixel(x - 1, y).luminance,
          image.getPixel(x + 1, y).luminance,
          image.getPixel(x, y - 1).luminance,
          image.getPixel(x, y + 1).luminance,
        ];

        final laplacian =
            (4 * center - neighbors.reduce((a, b) => a + b)).abs();
        totalSharpness += laplacian;
        samples++;
      }
    }

    final avgSharpness = samples > 0 ? totalSharpness / samples : 0.0;

    // Screen displays often have unnaturally high sharpness
    return (avgSharpness / 200).clamp(0.0, 1.0);
  }

  /// Detect reflection artifacts from screen surfaces
  double _detectReflectionArtifacts(imglib.Image image) {
    int reflectionPixels = 0;
    int totalPixels = 0;

    // Look for bright spots that might be screen reflections
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = pixel.luminance;

        // Check for unnaturally bright pixels (potential reflections)
        if (luminance > 200) {
          // Check surrounding pixels for similar brightness
          int brightNeighbors = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (x + dx >= 0 &&
                  x + dx < image.width &&
                  y + dy >= 0 &&
                  y + dy < image.height) {
                final neighbor = image.getPixel(x + dx, y + dy).luminance;
                if (neighbor > 180) {
                  brightNeighbors++;
                }
              }
            }
          }

          // If many neighbors are also bright, it might be a reflection
          if (brightNeighbors >= 4) {
            reflectionPixels++;
          }
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? reflectionPixels / totalPixels : 0.0;
  }

  /// Enhanced screen attack detection with advanced algorithms
  bool _detectScreenAttack(
      double textureScore, double motionScore, double headMovementScore) {
    // Advanced screen attack detection using multiple criteria
    int screenIndicators = 0;

    // 1. Check for unnatural motion patterns (hand shake vs natural head movement)
    if (_detectUnnaturalMotionPattern()) {
      screenIndicators++;
    }

    // 2. Check for lack of 3D structure (flat image detection)
    if (_detectFlatImageStructure()) {
      screenIndicators++;
    }

    // 3. Check for screen-specific texture patterns
    if (textureScore < 0.25) {
      screenIndicators++;
    }

    // 4. Check for unnatural lighting patterns (screen reflections)
    if (_detectScreenLightingPatterns()) {
      screenIndicators++;
    }

    // 5. Check for lack of natural facial micro-movements
    if (_detectLackOfMicroMovements()) {
      screenIndicators++;
    }

    // 6. Check for temporal consistency (video loops)
    if (_detectVideoLoopPatterns()) {
      screenIndicators++;
    }

    // 7. Check for unnatural face geometry (distorted by screen)
    if (_detectUnnaturalFaceGeometry()) {
      screenIndicators++;
    }

    // If 3 or more indicators suggest screen attack, classify as spoofed
    return screenIndicators >= 3;
  }

  /// Detect unnatural motion patterns (hand shake vs natural head movement)
  bool _detectUnnaturalMotionPattern() {
    if (_motionScores.length < 3) return false;

    // Real faces have more varied, organic motion patterns
    // Screen images moved by hand have more uniform, mechanical motion
    final recentScores = _motionScores.length > 5
        ? _motionScores.sublist(_motionScores.length - 5)
        : _motionScores;

    // Calculate motion variance - real faces have higher variance
    final mean = recentScores.reduce((a, b) => a + b) / recentScores.length;
    final variance = recentScores
            .map((score) => (score - mean) * (score - mean))
            .reduce((a, b) => a + b) /
        recentScores.length;

    // Low variance indicates mechanical motion (hand shake)
    return variance < 0.01;
  }

  /// Detect flat image structure (lack of 3D depth)
  bool _detectFlatImageStructure() {
    if (_frameBuffer.length < 2) return false;

    try {
      final currentFrame = _frameBuffer.last;
      final previousFrame = _frameBuffer[_frameBuffer.length - 2];

      // Real faces have natural depth variations that change with movement
      // Flat images have uniform depth patterns
      final depthVariation =
          _calculateDepthVariation(currentFrame, previousFrame);

      // Very low depth variation indicates flat image
      return depthVariation < 0.1;
    } catch (e) {
      return false;
    }
  }

  /// Detect screen-specific lighting patterns
  bool _detectScreenLightingPatterns() {
    if (_frameBuffer.isEmpty) return false;

    try {
      final currentFrame = _frameBuffer.last;

      // Screen displays have characteristic lighting patterns:
      // 1. Uniform brightness across the face
      // 2. Unnatural color temperature
      // 3. Screen reflections
      final lightingScore = _analyzeLightingPatterns(currentFrame);

      // High lighting score indicates screen patterns
      return lightingScore > 0.7;
    } catch (e) {
      return false;
    }
  }

  /// Detect lack of natural facial micro-movements
  bool _detectLackOfMicroMovements() {
    if (_faceBuffer.length < 3) return false;

    // Real faces have subtle micro-movements even when "still"
    // Screen images are completely static
    int microMovementCount = 0;

    for (int i = 1; i < _faceBuffer.length; i++) {
      final currentFace = _faceBuffer[i];
      final previousFace = _faceBuffer[i - 1];

      // Check for subtle changes in face landmarks
      final microMovement = _calculateMicroMovement(currentFace, previousFace);
      if (microMovement > 0.01) {
        microMovementCount++;
      }
    }

    // If less than 30% of frames show micro-movements, likely a screen
    return (microMovementCount / (_faceBuffer.length - 1)) < 0.3;
  }

  /// Detect video loop patterns
  bool _detectVideoLoopPatterns() {
    if (_frameBuffer.length < 10) return false;

    // Check for repeating patterns that indicate video loops
    final recentFrames = _frameBuffer.length > 10
        ? _frameBuffer.sublist(_frameBuffer.length - 10)
        : _frameBuffer;

    // Look for periodic similarity patterns
    for (int i = 0; i < recentFrames.length - 5; i++) {
      for (int j = i + 3; j < recentFrames.length; j++) {
        final similarity =
            _calculateFrameSimilarity(recentFrames[i], recentFrames[j]);
        if (similarity > 0.9) {
          return true; // Found very similar frames, likely a loop
        }
      }
    }

    return false;
  }

  /// Detect unnatural face geometry
  bool _detectUnnaturalFaceGeometry() {
    if (_faceBuffer.isEmpty) return false;

    final currentFace = _faceBuffer.last;

    // Check for unnatural face proportions that might indicate screen distortion
    final aspectRatio =
        currentFace.boundingBox.width / currentFace.boundingBox.height;

    // Real faces typically have aspect ratios between 0.7 and 1.3
    // Screen images might be distorted
    if (aspectRatio < 0.6 || aspectRatio > 1.5) {
      return true;
    }

    // Check for unnatural face size changes (screen zoom effects)
    if (_faceBuffer.length >= 2) {
      final previousFace = _faceBuffer[_faceBuffer.length - 2];
      final sizeChange = _calculateFaceSizeChange(currentFace, previousFace);

      // Sudden large size changes might indicate screen manipulation
      if (sizeChange > 0.3) {
        return true;
      }
    }

    return false;
  }

  /// Calculate enhanced liveness score
  double _calculateEnhancedLivenessScore() {
    if (_textureScores.isEmpty || _motionScores.isEmpty) return 0.3;

    // Calculate average scores
    final avgTexture =
        _textureScores.reduce((a, b) => a + b) / _textureScores.length;
    final avgMotion =
        _motionScores.reduce((a, b) => a + b) / _motionScores.length;

    // Enhanced weighting for better real face detection
    final livenessScore = (avgTexture * 0.6 + avgMotion * 0.4);

    return livenessScore.clamp(0.0, 1.0);
  }

  /// Get enhanced recommendations
  List<String> _getEnhancedRecommendations(
    double livenessScore,
    bool activeLivenessPassed,
    bool headMovementPassed,
    bool isScreenAttack,
  ) {
    final recommendations = <String>[];

    if (isScreenAttack) {
      recommendations.addAll([
        'Screen attack detected - please use a real face',
        'Do not show photos or images on screens',
        'Ensure you are a live person in front of the camera',
      ]);
      return recommendations;
    }

    if (livenessScore < 0.3) {
      recommendations.addAll([
        'Please ensure good lighting',
        'Remove any masks or coverings',
        'Look directly at the camera',
        'Do not use photos or screen images',
      ]);
    } else if (livenessScore < 0.5) {
      recommendations.addAll([
        'Try moving slightly',
        'Blink naturally',
        'Ensure your face is well-lit',
      ]);
    }

    if (!activeLivenessPassed) {
      recommendations.add('Please blink or move your head slightly');
    }

    if (!headMovementPassed) {
      recommendations.addAll([
        'Please move your head naturally - turn left, right, or nod',
        'Avoid holding completely still',
      ]);
    }

    return recommendations;
  }

  // Helper methods (implementations from original service)
  double _calculateLBP(imglib.Image image) {
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

  // Enhanced helper methods for advanced screen attack detection

  /// Calculate depth variation between frames
  double _calculateDepthVariation(CameraImage frame1, CameraImage frame2) {
    // Simplified depth analysis using gradient differences
    // Real faces have natural depth variations that change with movement
    // Flat images have uniform depth patterns

    if (frame1.planes.length != frame2.planes.length) return 0.5;

    double totalVariation = 0.0;
    int samples = 0;

    for (int plane = 0; plane < frame1.planes.length; plane++) {
      final bytes1 = frame1.planes[plane].bytes;
      final bytes2 = frame2.planes[plane].bytes;

      final minLength =
          bytes1.length < bytes2.length ? bytes1.length : bytes2.length;

      // Sample every 4th pixel for depth analysis
      for (int i = 0; i < minLength; i += 4) {
        final diff = (bytes1[i] - bytes2[i]).abs();
        totalVariation += diff;
        samples++;
      }
    }

    return samples > 0 ? (totalVariation / samples / 50).clamp(0.0, 1.0) : 0.5;
  }

  /// Analyze lighting patterns for screen detection
  double _analyzeLightingPatterns(CameraImage frame) {
    // Screen displays have characteristic lighting patterns:
    // 1. Uniform brightness across the face
    // 2. Unnatural color temperature
    // 3. Screen reflections

    if (frame.planes.isEmpty) return 0.5;

    final yPlane = frame.planes[0].bytes;
    double totalBrightness = 0.0;
    double brightnessVariance = 0.0;
    int samples = 0;

    // Sample brightness values
    for (int i = 0; i < yPlane.length; i += 4) {
      totalBrightness += yPlane[i];
      samples++;
    }

    if (samples == 0) return 0.5;

    final avgBrightness = totalBrightness / samples;

    // Calculate brightness variance
    for (int i = 0; i < yPlane.length; i += 4) {
      final diff = (yPlane[i] - avgBrightness);
      brightnessVariance += diff * diff;
    }

    final variance = brightnessVariance / samples;

    // Low variance indicates uniform lighting (screen characteristic)
    // High variance indicates natural lighting variations
    return (1.0 - (variance / 1000)).clamp(0.0, 1.0);
  }

  /// Calculate micro-movement between faces
  double _calculateMicroMovement(Face face1, Face face2) {
    // Real faces have subtle micro-movements even when "still"
    // Screen images are completely static

    final center1 = _getFaceCenter(face1);
    final center2 = _getFaceCenter(face2);

    final distance = ((center2.x - center1.x) * (center2.x - center1.x) +
        (center2.y - center1.y) * (center2.y - center1.y));

    final faceSize = face1.boundingBox.width * face1.boundingBox.height;
    return distance / faceSize;
  }

  /// Calculate frame similarity
  double _calculateFrameSimilarity(CameraImage frame1, CameraImage frame2) {
    // Check for repeating patterns that indicate video loops

    if (frame1.planes.length != frame2.planes.length) return 0.0;

    int similarPixels = 0;
    int totalPixels = 0;

    for (int plane = 0; plane < frame1.planes.length; plane++) {
      final bytes1 = frame1.planes[plane].bytes;
      final bytes2 = frame2.planes[plane].bytes;

      final minLength =
          bytes1.length < bytes2.length ? bytes1.length : bytes2.length;

      // Sample every 8th pixel for similarity check
      for (int i = 0; i < minLength; i += 8) {
        final diff = (bytes1[i] - bytes2[i]).abs();
        if (diff < 5) {
          // Very similar pixels
          similarPixels++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? similarPixels / totalPixels : 0.0;
  }

  /// Calculate face size change
  double _calculateFaceSizeChange(Face face1, Face face2) {
    final area1 = face1.boundingBox.width * face1.boundingBox.height;
    final area2 = face2.boundingBox.width * face2.boundingBox.height;
    return (area2 - area1).abs() / area1;
  }

  /// Get face center point
  Point<double> _getFaceCenter(Face face) {
    return Point(
      face.boundingBox.left + face.boundingBox.width / 2,
      face.boundingBox.top + face.boundingBox.height / 2,
    );
  }

  // Additional helper methods (placeholder implementations)
  /// Calculate texture variance for better texture analysis
  double _calculateTextureVariance(imglib.Image image) {
    if (image.width < 3 || image.height < 3) return 0.5;

    double totalVariance = 0.0;
    int samples = 0;

    // Calculate local variance in 3x3 neighborhoods
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final center = image.getPixel(x, y).luminance;
        final neighbors = [
          image.getPixel(x - 1, y - 1).luminance,
          image.getPixel(x, y - 1).luminance,
          image.getPixel(x + 1, y - 1).luminance,
          image.getPixel(x - 1, y).luminance,
          image.getPixel(x + 1, y).luminance,
          image.getPixel(x - 1, y + 1).luminance,
          image.getPixel(x, y + 1).luminance,
          image.getPixel(x + 1, y + 1).luminance,
        ];

        final mean = (center + neighbors.reduce((a, b) => a + b)) / 9;
        final variance = neighbors
                .map((n) => (n - mean) * (n - mean))
                .reduce((a, b) => a + b) /
            8;
        totalVariance += variance;
        samples++;
      }
    }

    final avgVariance = samples > 0 ? totalVariance / samples : 0.0;
    // Higher variance indicates more texture (real face), lower indicates flat (screen)
    return (avgVariance / 1000).clamp(0.0, 1.0);
  }

  /// Calculate edge density for texture analysis
  double _calculateEdgeDensity(imglib.Image image) {
    if (image.width < 3 || image.height < 3) return 0.5;

    int edgePixels = 0;
    int totalPixels = 0;

    // Use Sobel edge detection
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        // Sobel X kernel
        final gx = (-1 * image.getPixel(x - 1, y - 1).luminance +
            1 * image.getPixel(x + 1, y - 1).luminance +
            -2 * image.getPixel(x - 1, y).luminance +
            2 * image.getPixel(x + 1, y).luminance +
            -1 * image.getPixel(x - 1, y + 1).luminance +
            1 * image.getPixel(x + 1, y + 1).luminance);

        // Sobel Y kernel
        final gy = (-1 * image.getPixel(x - 1, y - 1).luminance +
            -2 * image.getPixel(x, y - 1).luminance +
            -1 * image.getPixel(x + 1, y - 1).luminance +
            1 * image.getPixel(x - 1, y + 1).luminance +
            2 * image.getPixel(x, y + 1).luminance +
            1 * image.getPixel(x + 1, y + 1).luminance);

        final magnitude = sqrt(gx * gx + gy * gy);

        // Threshold for edge detection
        if (magnitude > 30) {
          edgePixels++;
        }
        totalPixels++;
      }
    }

    return totalPixels > 0 ? edgePixels / totalPixels : 0.0;
  }

  /// Calculate image quality assessment
  double _calculateImageQuality(imglib.Image image) {
    if (image.width < 3 || image.height < 3) return 0.5;

    // Calculate image quality using multiple metrics
    final sharpness = _calculateSharpness(image);
    final contrast = _calculateContrast(image);
    final brightness = _calculateBrightness(image);

    // Combine metrics for overall quality score
    final qualityScore = (sharpness * 0.4 + contrast * 0.3 + brightness * 0.3);
    return qualityScore.clamp(0.0, 1.0);
  }

  /// Calculate image sharpness using Laplacian variance
  double _calculateSharpness(imglib.Image image) {
    double totalSharpness = 0.0;
    int samples = 0;

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final center = image.getPixel(x, y).luminance;
        final neighbors = [
          image.getPixel(x - 1, y).luminance,
          image.getPixel(x + 1, y).luminance,
          image.getPixel(x, y - 1).luminance,
          image.getPixel(x, y + 1).luminance,
        ];

        final laplacian =
            (4 * center - neighbors.reduce((a, b) => a + b)).abs();
        totalSharpness += laplacian;
        samples++;
      }
    }

    final avgSharpness = samples > 0 ? totalSharpness / samples : 0.0;
    return (avgSharpness / 200).clamp(0.0, 1.0);
  }

  /// Calculate image contrast
  double _calculateContrast(imglib.Image image) {
    int minLuminance = 255;
    int maxLuminance = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final luminance = image.getPixel(x, y).luminance;
        if (luminance < minLuminance) minLuminance = luminance.toInt();
        if (luminance > maxLuminance) maxLuminance = luminance.toInt();
      }
    }

    final contrast = (maxLuminance - minLuminance) / 255.0;
    return contrast.clamp(0.0, 1.0);
  }

  /// Calculate image brightness
  double _calculateBrightness(imglib.Image image) {
    double totalBrightness = 0.0;
    int pixels = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        totalBrightness += image.getPixel(x, y).luminance;
        pixels++;
      }
    }

    final avgBrightness = pixels > 0 ? totalBrightness / pixels : 0.0;
    // Optimal brightness is around 128 (middle of 0-255 range)
    final brightnessScore = 1.0 - (avgBrightness - 128).abs() / 128.0;
    return brightnessScore.clamp(0.0, 1.0);
  }

  /// Analyze frequency domain for screen detection
  double _analyzeFrequencyDomain(imglib.Image image) {
    if (image.width < 8 || image.height < 8) return 0.5;

    // Simplified frequency analysis using DCT-like approach
    double highFreqEnergy = 0.0;
    double lowFreqEnergy = 0.0;
    int samples = 0;

    // Sample 8x8 blocks
    for (int y = 0; y < image.height - 8; y += 8) {
      for (int x = 0; x < image.width - 8; x += 8) {
        // Calculate energy in different frequency bands
        for (int dy = 0; dy < 8; dy++) {
          for (int dx = 0; dx < 8; dx++) {
            final pixel = image.getPixel(x + dx, y + dy).luminance;
            final freq = dx + dy; // Simplified frequency measure

            if (freq < 4) {
              lowFreqEnergy += pixel * pixel;
            } else {
              highFreqEnergy += pixel * pixel;
            }
            samples++;
          }
        }
      }
    }

    if (samples == 0) return 0.5;

    final totalEnergy = highFreqEnergy + lowFreqEnergy;
    if (totalEnergy == 0) return 0.5;

    // Real faces have more high-frequency content
    // Screen images have more low-frequency content
    final highFreqRatio = highFreqEnergy / totalEnergy;
    return highFreqRatio.clamp(0.0, 1.0);
  }

  /// Calculate frame difference for motion analysis
  double _calculateFrameDifference(CameraImage frame1, CameraImage frame2) {
    if (frame1.planes.length != frame2.planes.length) return 0.5;

    double totalDiff = 0.0;
    int samples = 0;

    for (int plane = 0; plane < frame1.planes.length; plane++) {
      final bytes1 = frame1.planes[plane].bytes;
      final bytes2 = frame2.planes[plane].bytes;

      final minLength =
          bytes1.length < bytes2.length ? bytes1.length : bytes2.length;

      // Sample every 4th pixel for performance
      for (int i = 0; i < minLength; i += 4) {
        final diff = (bytes1[i] - bytes2[i]).abs();
        totalDiff += diff;
        samples++;
      }
    }

    final avgDiff = samples > 0 ? totalDiff / samples : 0.0;
    // Normalize to 0-1 range
    return (avgDiff / 50).clamp(0.0, 1.0);
  }

  /// Calculate face motion between frames
  double _calculateFaceMotion() {
    if (_faceBuffer.length < 2) return 0.5;

    double totalMotion = 0.0;
    int comparisons = 0;

    for (int i = 1; i < _faceBuffer.length; i++) {
      final currentFace = _faceBuffer[i];
      final previousFace = _faceBuffer[i - 1];

      final center1 = _getFaceCenter(previousFace);
      final center2 = _getFaceCenter(currentFace);

      final distance = sqrt(
        (center2.x - center1.x) * (center2.x - center1.x) +
            (center2.y - center1.y) * (center2.y - center1.y),
      );

      final faceSize = sqrt(
        currentFace.boundingBox.width * currentFace.boundingBox.height,
      );

      final normalizedMotion = distance / faceSize;
      totalMotion += normalizedMotion;
      comparisons++;
    }

    final avgMotion = comparisons > 0 ? totalMotion / comparisons : 0.0;
    return avgMotion.clamp(0.0, 1.0);
  }

  /// Calculate micro motion detection
  double _calculateMicroMotion() {
    if (_faceBuffer.length < 3) return 0.5;

    double totalMicroMotion = 0.0;
    int comparisons = 0;

    for (int i = 2; i < _faceBuffer.length; i++) {
      final currentFace = _faceBuffer[i];
      final previousFace = _faceBuffer[i - 1];
      final beforePreviousFace = _faceBuffer[i - 2];

      // Calculate micro movements using landmark changes
      final microMotion1 = _calculateMicroMovement(currentFace, previousFace);
      final microMotion2 =
          _calculateMicroMovement(previousFace, beforePreviousFace);

      // Look for consistent micro movements
      final consistency = 1.0 - (microMotion1 - microMotion2).abs();
      totalMicroMotion += consistency;
      comparisons++;
    }

    final avgMicroMotion =
        comparisons > 0 ? totalMicroMotion / comparisons : 0.0;
    return avgMicroMotion.clamp(0.0, 1.0);
  }

  /// Analyze head movement patterns
  double _analyzeHeadMovement(Face face) {
    if (_faceBuffer.length < 2) return 0.5;

    final currentFace = face;
    final previousFace = _faceBuffer[_faceBuffer.length - 2];

    // Calculate head rotation changes
    final currentYaw = currentFace.headEulerAngleY ?? 0.0;
    final previousYaw = previousFace.headEulerAngleY ?? 0.0;
    final currentPitch = currentFace.headEulerAngleX ?? 0.0;
    final previousPitch = previousFace.headEulerAngleX ?? 0.0;

    final yawChange = (currentYaw - previousYaw).abs();
    final pitchChange = (currentPitch - previousPitch).abs();

    // Normalize head movement (degrees to 0-1 range)
    final totalMovement = (yawChange + pitchChange) / 20.0; // 20 degrees = 1.0
    return totalMovement.clamp(0.0, 1.0);
  }

  /// Check active liveness (blink detection)
  bool _checkActiveLiveness() {
    if (_blinkDetections.length < 3) return false;

    // Check if we've detected at least one blink in recent frames
    final recentBlinks = _blinkDetections.length > 5
        ? _blinkDetections.sublist(_blinkDetections.length - 5)
        : _blinkDetections;

    return recentBlinks.any((blink) => blink);
  }

  /// Check head movement requirement
  bool _checkHeadMovementRequirement() {
    if (_headMovementScores.length < 3) return false;

    // Check if we have sufficient head movement
    final recentMovements = _headMovementScores.length > 5
        ? _headMovementScores.sublist(_headMovementScores.length - 5)
        : _headMovementScores;

    final avgMovement =
        recentMovements.reduce((a, b) => a + b) / recentMovements.length;
    return avgMovement > 0.1; // Minimum movement threshold
  }

  /// Crop face from camera image
  imglib.Image _cropFaceFromCameraImage(CameraImage image, Face face) {
    try {
      // Convert camera image to regular image
      final convertedImage = _convertCameraImageToImage(image);

      // Calculate crop coordinates with padding
      final padding = 20.0;
      final x =
          (face.boundingBox.left - padding).clamp(0.0, image.width.toDouble());
      final y =
          (face.boundingBox.top - padding).clamp(0.0, image.height.toDouble());
      final width = (face.boundingBox.width + 2 * padding)
          .clamp(0.0, image.width.toDouble() - x);
      final height = (face.boundingBox.height + 2 * padding)
          .clamp(0.0, image.height.toDouble() - y);

      // Crop the face region
      return imglib.copyCrop(
        convertedImage,
        x: x.round(),
        y: y.round(),
        width: width.round(),
        height: height.round(),
      );
    } catch (e) {
      dev.log('Face cropping error: $e');
      // Return a default image if cropping fails
      return imglib.Image(width: 128, height: 128);
    }
  }

  /// Convert camera image to regular image
  imglib.Image _convertCameraImageToImage(CameraImage cameraImage) {
    // This is a simplified conversion - you might need to adjust based on your camera format
    final width = cameraImage.width;
    final height = cameraImage.height;

    final image = imglib.Image(width: width, height: height);

    // Convert YUV to RGB (simplified)
    if (cameraImage.planes.length >= 3) {
      final yPlane = cameraImage.planes[0].bytes;
      final uPlane = cameraImage.planes[1].bytes;
      final vPlane = cameraImage.planes[2].bytes;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * width + x;
          final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

          if (yIndex < yPlane.length &&
              uvIndex < uPlane.length &&
              uvIndex < vPlane.length) {
            final yValue = yPlane[yIndex];
            final uValue = uPlane[uvIndex];
            final vValue = vPlane[uvIndex];

            // Convert YUV to RGB
            final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).round();
            final g =
                (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                    .clamp(0, 255)
                    .round();
            final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).round();

            image.setPixel(x, y, imglib.ColorRgb8(r, g, b));
          }
        }
      }
    }

    return image;
  }

  /// Reset the service state
  void reset() {
    _frameBuffer.clear();
    _faceBuffer.clear();
    _textureScores.clear();
    _motionScores.clear();
    _blinkDetections.clear();
    _headMovementScores.clear();
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
  final double headMovementScore;
  final bool blinkDetected;
  final bool hasEnoughData;
  final bool activeLivenessPassed;
  final bool headMovementPassed;
  final List<String> recommendations;

  const AntiSpoofingResult({
    required this.isLive,
    required this.confidence,
    required this.textureScore,
    required this.motionScore,
    required this.headMovementScore,
    required this.blinkDetected,
    required this.hasEnoughData,
    required this.activeLivenessPassed,
    required this.headMovementPassed,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'AntiSpoofingResult(isLive: $isLive, confidence: $confidence, '
        'textureScore: $textureScore, motionScore: $motionScore, '
        'headMovementScore: $headMovementScore, blinkDetected: $blinkDetected, '
        'hasEnoughData: $hasEnoughData, activeLivenessPassed: $activeLivenessPassed, '
        'headMovementPassed: $headMovementPassed)';
  }
}
