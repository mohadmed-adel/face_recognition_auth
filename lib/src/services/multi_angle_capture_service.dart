import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Enum for different capture angles
enum CaptureAngle {
  front,
  left,
  right,
  up,
}

/// Service for capturing faces from multiple angles with head movement detection
class MultiAngleCaptureService {
  static const int _requiredSamplesPerAngle = 3;
  static const int _maxAttemptsPerAngle = 10;
  static const Duration _angleTimeout = Duration(seconds: 15);
  static const double _minHeadMovementThreshold = 0.15; // 15% of face size
  static const double _maxHeadMovementThreshold = 0.4; // 40% of face size

  final Map<CaptureAngle, List<List<num>>> _angleSamples = {};
  final Map<CaptureAngle, bool> _angleCompleted = {};
  final Map<CaptureAngle, int> _angleAttempts = {};

  CaptureAngle _currentAngle = CaptureAngle.front;
  Face? _lastFace;
  bool _isCapturing = false;
  Timer? _angleTimer;

  /// Callback for angle change notifications
  Function(CaptureAngle angle, String instruction)? onAngleChanged;

  /// Callback for progress updates
  Function(CaptureAngle angle, int samplesCollected, int requiredSamples)?
      onProgress;

  /// Callback for head movement detection
  Function(bool movementDetected, String instruction)? onMovementDetected;

  /// Callback for completion
  Function(Map<CaptureAngle, List<List<num>>> allSamples)? onCompleted;

  /// Callback for errors
  Function(String error)? onError;

  /// Start multi-angle capture process
  Future<Map<CaptureAngle, List<List<num>>>> startCapture({
    required CameraImage image,
    required Face face,
    required List<num> embedding,
  }) async {
    if (_isCapturing) {
      throw StateError('Capture already in progress');
    }

    _isCapturing = true;
    _initializeCapture();

    try {
      // Start with front angle
      await _processAngle(image, face, embedding);

      // Wait for all angles to complete
      while (!_allAnglesCompleted()) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return Map.from(_angleSamples);
    } finally {
      _isCapturing = false;
      _angleTimer?.cancel();
    }
  }

  /// Process current angle capture
  Future<void> _processAngle(
      CameraImage image, Face face, List<num> embedding) async {
    // Check if current angle is already completed
    if (_angleCompleted[_currentAngle] == true) {
      _moveToNextAngle();
      return;
    }

    // Check attempts limit
    if ((_angleAttempts[_currentAngle] ?? 0) >= _maxAttemptsPerAngle) {
      onError?.call('Maximum attempts reached for ${_currentAngle.name} angle');
      _moveToNextAngle();
      return;
    }

    // Increment attempts
    _angleAttempts[_currentAngle] = (_angleAttempts[_currentAngle] ?? 0) + 1;

    // Check for head movement if not front angle
    if (_currentAngle != CaptureAngle.front) {
      final movementDetected = _detectHeadMovement(face);
      if (!movementDetected) {
        _provideMovementInstruction();
        return;
      }
    }

    // Validate face quality for current angle
    if (!_validateFaceForAngle(face, _currentAngle)) {
      _provideAngleInstruction();
      return;
    }

    // Add sample for current angle
    _addSampleForAngle(_currentAngle, embedding);

    // Update progress
    final samplesCollected = _angleSamples[_currentAngle]?.length ?? 0;
    onProgress?.call(_currentAngle, samplesCollected, _requiredSamplesPerAngle);

    // Check if angle is complete
    if (samplesCollected >= _requiredSamplesPerAngle) {
      _angleCompleted[_currentAngle] = true;
      _moveToNextAngle();
    }
  }

  /// Detect head movement between frames
  bool _detectHeadMovement(Face currentFace) {
    if (_lastFace == null) {
      _lastFace = currentFace;
      return false;
    }

    // Calculate face position change
    final positionChange =
        _calculateFacePositionChange(_lastFace!, currentFace);
    final sizeChange = _calculateFaceSizeChange(_lastFace!, currentFace);

    // Check if movement is within acceptable range
    final hasMovement = positionChange > _minHeadMovementThreshold &&
        positionChange < _maxHeadMovementThreshold;

    final hasSizeChange = sizeChange > 0.05; // 5% size change

    if (hasMovement || hasSizeChange) {
      onMovementDetected?.call(true, 'Good movement detected!');
      _lastFace = currentFace;
      return true;
    }

    return false;
  }

  /// Calculate face position change between frames
  double _calculateFacePositionChange(Face face1, Face face2) {
    final center1 = _getFaceCenter(face1);
    final center2 = _getFaceCenter(face2);

    final distance =
        sqrt(pow(center2.x - center1.x, 2) + pow(center2.y - center1.y, 2));

    // Normalize by face size
    final faceSize = max(face1.boundingBox.width, face1.boundingBox.height);
    return distance / faceSize;
  }

  /// Calculate face size change between frames
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

  /// Validate face for specific angle
  bool _validateFaceForAngle(Face face, CaptureAngle angle) {
    switch (angle) {
      case CaptureAngle.front:
        return _validateFrontAngle(face);
      case CaptureAngle.left:
        return _validateLeftAngle(face);
      case CaptureAngle.right:
        return _validateRightAngle(face);
      case CaptureAngle.up:
        return _validateUpAngle(face);
    }
  }

  /// Validate face for front angle
  bool _validateFrontAngle(Face face) {
    // Check if face is centered and looking forward
    // Face should be roughly centered (within 20% of frame center)
    return true; // Simplified for now
  }

  /// Validate face for left angle
  bool _validateLeftAngle(Face face) {
    // Check if face is turned to the left
    // This would require more sophisticated analysis in a real implementation
    return true; // Simplified for now
  }

  /// Validate face for right angle
  bool _validateRightAngle(Face face) {
    // Check if face is turned to the right
    return true; // Simplified for now
  }

  /// Validate face for up angle
  bool _validateUpAngle(Face face) {
    // Check if face is looking up
    return true; // Simplified for now
  }

  /// Add sample for specific angle
  void _addSampleForAngle(CaptureAngle angle, List<num> embedding) {
    _angleSamples[angle] ??= [];
    _angleSamples[angle]!.add(List.from(embedding));
  }

  /// Move to next angle
  void _moveToNextAngle() {
    switch (_currentAngle) {
      case CaptureAngle.front:
        _currentAngle = CaptureAngle.left;
        break;
      case CaptureAngle.left:
        _currentAngle = CaptureAngle.right;
        break;
      case CaptureAngle.right:
        _currentAngle = CaptureAngle.up;
        break;
      case CaptureAngle.up:
        // All angles completed
        onCompleted?.call(_angleSamples);
        return;
    }

    _notifyAngleChange();
    _startAngleTimer();
  }

  /// Notify about angle change
  void _notifyAngleChange() {
    final instruction = _getAngleInstruction(_currentAngle);
    onAngleChanged?.call(_currentAngle, instruction);
  }

  /// Get instruction for specific angle
  String _getAngleInstruction(CaptureAngle angle) {
    switch (angle) {
      case CaptureAngle.front:
        return 'Look directly at the camera';
      case CaptureAngle.left:
        return 'Turn your head to the left';
      case CaptureAngle.right:
        return 'Turn your head to the right';
      case CaptureAngle.up:
        return 'Look up slightly';
    }
  }

  /// Provide movement instruction
  void _provideMovementInstruction() {
    final instruction = _getMovementInstruction(_currentAngle);
    onMovementDetected?.call(false, instruction);
  }

  /// Get movement instruction for current angle
  String _getMovementInstruction(CaptureAngle angle) {
    switch (angle) {
      case CaptureAngle.front:
        return 'Please look directly at the camera';
      case CaptureAngle.left:
        return 'Please turn your head to the left';
      case CaptureAngle.right:
        return 'Please turn your head to the right';
      case CaptureAngle.up:
        return 'Please look up slightly';
    }
  }

  /// Provide angle-specific instruction
  void _provideAngleInstruction() {
    final instruction = _getAngleInstruction(_currentAngle);
    onError?.call(instruction);
  }

  /// Start timer for current angle
  void _startAngleTimer() {
    _angleTimer?.cancel();
    _angleTimer = Timer(_angleTimeout, () {
      onError?.call(
          'Timeout for ${_currentAngle.name} angle. Moving to next angle.');
      _moveToNextAngle();
    });
  }

  /// Check if all angles are completed
  bool _allAnglesCompleted() {
    return CaptureAngle.values.every((angle) => _angleCompleted[angle] == true);
  }

  /// Initialize capture state
  void _initializeCapture() {
    _angleSamples.clear();
    _angleCompleted.clear();
    _angleAttempts.clear();

    for (final angle in CaptureAngle.values) {
      _angleCompleted[angle] = false;
      _angleAttempts[angle] = 0;
    }

    _currentAngle = CaptureAngle.front;
    _lastFace = null;

    _notifyAngleChange();
    _startAngleTimer();
  }

  /// Get current angle
  CaptureAngle get currentAngle => _currentAngle;

  /// Get progress for current angle
  Map<String, int> get currentProgress {
    final samplesCollected = _angleSamples[_currentAngle]?.length ?? 0;
    return {
      'current': samplesCollected,
      'required': _requiredSamplesPerAngle,
      'attempts': _angleAttempts[_currentAngle] ?? 0,
    };
  }

  /// Get overall progress
  Map<String, dynamic> get overallProgress {
    final completedAngles =
        _angleCompleted.values.where((completed) => completed).length;
    final totalAngles = CaptureAngle.values.length;

    return {
      'completedAngles': completedAngles,
      'totalAngles': totalAngles,
      'currentAngle': _currentAngle.name,
      'angleProgress': Map.from(_angleSamples
          .map((angle, samples) => MapEntry(angle.name, samples.length))),
    };
  }

  /// Reset the service
  void reset() {
    _isCapturing = false;
    _angleTimer?.cancel();
    _angleSamples.clear();
    _angleCompleted.clear();
    _angleAttempts.clear();
    _currentAngle = CaptureAngle.front;
    _lastFace = null;
  }

  /// Dispose resources
  void dispose() {
    reset();
  }
}
