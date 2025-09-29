/// Comprehensive error types for face recognition authentication
enum FaceAuthErrorType {
  // Camera related errors
  cameraInitializationFailed,
  cameraPermissionDenied,
  cameraNotAvailable,

  // Face detection errors
  noFaceDetected,
  multipleFacesDetected,
  faceDetectionFailed,

  // Registration errors
  userAlreadyExists,
  faceAlreadyRegistered,
  registrationTimeout,
  insufficientSamples,

  // Authentication errors
  authenticationFailed,
  authenticationTimeout,
  userNotFound,

  // Database errors
  databaseError,
  databaseInitializationFailed,

  // ML/AI errors
  modelLoadingFailed,
  embeddingGenerationFailed,
  predictionFailed,

  // Anti-spoofing errors
  spoofingDetected,
  insufficientLivenessData,
  livenessCheckFailed,
  photoAttackDetected,
  screenAttackDetected,

  // System errors
  operationInProgress,
  systemError,
  unknownError,
}

/// Structured error class for face authentication
class FaceAuthError implements Exception {
  final FaceAuthErrorType type;
  final String message;
  final String? details;
  final dynamic originalError;

  const FaceAuthError({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
  });

  /// Create error from type with default message
  factory FaceAuthError.fromType(FaceAuthErrorType type,
      {String? details, dynamic originalError}) {
    return FaceAuthError(
      type: type,
      message: _getDefaultMessage(type),
      details: details,
      originalError: originalError,
    );
  }

  /// Create error from string message (for backward compatibility)
  factory FaceAuthError.fromMessage(String message,
      {String? details, dynamic originalError}) {
    final type = _parseErrorType(message);
    return FaceAuthError(
      type: type,
      message: message,
      details: details,
      originalError: originalError,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case FaceAuthErrorType.cameraInitializationFailed:
        return 'Failed to initialize camera. Please check camera permissions.';
      case FaceAuthErrorType.cameraPermissionDenied:
        return 'Camera permission denied. Please enable camera access in settings.';
      case FaceAuthErrorType.cameraNotAvailable:
        return 'Camera not available on this device.';
      case FaceAuthErrorType.noFaceDetected:
        return 'No face detected. Please position your face in the camera view.';
      case FaceAuthErrorType.multipleFacesDetected:
        return 'Multiple faces detected. Please ensure only one person is in the camera view.';
      case FaceAuthErrorType.faceDetectionFailed:
        return 'Face detection failed. Please try again.';
      case FaceAuthErrorType.userAlreadyExists:
        return 'User ID already exists. Please choose a different user ID.';
      case FaceAuthErrorType.faceAlreadyRegistered:
        return 'This face is already registered. Please use a different face or login instead.';
      case FaceAuthErrorType.registrationTimeout:
        return 'Registration timed out. Please try again.';
      case FaceAuthErrorType.insufficientSamples:
        return 'Insufficient face samples collected. Please try again.';
      case FaceAuthErrorType.authenticationFailed:
        return 'Authentication failed. Face not recognized.';
      case FaceAuthErrorType.authenticationTimeout:
        return 'Authentication timed out. Please try again.';
      case FaceAuthErrorType.userNotFound:
        return 'User not found. Please register first.';
      case FaceAuthErrorType.databaseError:
        return 'Database error occurred. Please try again.';
      case FaceAuthErrorType.databaseInitializationFailed:
        return 'Failed to initialize database.';
      case FaceAuthErrorType.modelLoadingFailed:
        return 'Failed to load AI model. Please restart the app.';
      case FaceAuthErrorType.embeddingGenerationFailed:
        return 'Failed to generate face embedding. Please try again.';
      case FaceAuthErrorType.predictionFailed:
        return 'AI prediction failed. Please try again.';
      case FaceAuthErrorType.spoofingDetected:
        return 'Spoofing detected. Please ensure you are a real person and try again.';
      case FaceAuthErrorType.insufficientLivenessData:
        return 'Insufficient liveness data. Please move your head or blink naturally.';
      case FaceAuthErrorType.livenessCheckFailed:
        return 'Liveness check failed. Please ensure you are present and try again.';
      case FaceAuthErrorType.photoAttackDetected:
        return 'Photo attack detected. Please use a live camera feed, not a photo.';
      case FaceAuthErrorType.screenAttackDetected:
        return 'Screen attack detected. Please use a live camera feed, not a screen.';
      case FaceAuthErrorType.operationInProgress:
        return 'Another operation is in progress. Please wait.';
      case FaceAuthErrorType.systemError:
        return 'System error occurred. Please try again.';
      case FaceAuthErrorType.unknownError:
        return 'An unknown error occurred. Please try again.';
    }
  }

  /// Get technical error message for debugging
  String get technicalMessage {
    if (details != null) {
      return '$message (Details: $details)';
    }
    return message;
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    switch (type) {
      case FaceAuthErrorType.cameraPermissionDenied:
      case FaceAuthErrorType.noFaceDetected:
      case FaceAuthErrorType.multipleFacesDetected:
      case FaceAuthErrorType.registrationTimeout:
      case FaceAuthErrorType.authenticationTimeout:
      case FaceAuthErrorType.insufficientSamples:
        return true;
      default:
        return false;
    }
  }

  /// Check if error requires user action
  bool get requiresUserAction {
    switch (type) {
      case FaceAuthErrorType.cameraPermissionDenied:
      case FaceAuthErrorType.userAlreadyExists:
      case FaceAuthErrorType.faceAlreadyRegistered:
        return true;
      default:
        return false;
    }
  }

  /// Check if error is retryable
  bool get isRetryable {
    switch (type) {
      case FaceAuthErrorType.cameraPermissionDenied:
      case FaceAuthErrorType.noFaceDetected:
      case FaceAuthErrorType.multipleFacesDetected:
      case FaceAuthErrorType.registrationTimeout:
      case FaceAuthErrorType.authenticationTimeout:
      case FaceAuthErrorType.insufficientSamples:
      case FaceAuthErrorType.spoofingDetected:
      case FaceAuthErrorType.insufficientLivenessData:
      case FaceAuthErrorType.livenessCheckFailed:
      case FaceAuthErrorType.photoAttackDetected:
      case FaceAuthErrorType.screenAttackDetected:
      case FaceAuthErrorType.faceDetectionFailed:
      case FaceAuthErrorType.embeddingGenerationFailed:
      case FaceAuthErrorType.predictionFailed:
        return true;
      case FaceAuthErrorType.userAlreadyExists:
      case FaceAuthErrorType.faceAlreadyRegistered:
        return false; // These require different action, not retry
      default:
        return true; // Most errors are retryable
    }
  }

  @override
  String toString() => 'FaceAuthError(type: $type, message: $message)';

  /// Get default message for error type
  static String _getDefaultMessage(FaceAuthErrorType type) {
    switch (type) {
      case FaceAuthErrorType.cameraInitializationFailed:
        return 'Camera initialization failed';
      case FaceAuthErrorType.cameraPermissionDenied:
        return 'Camera permission denied';
      case FaceAuthErrorType.cameraNotAvailable:
        return 'Camera not available';
      case FaceAuthErrorType.noFaceDetected:
        return 'No face detected';
      case FaceAuthErrorType.multipleFacesDetected:
        return 'Multiple faces detected';
      case FaceAuthErrorType.faceDetectionFailed:
        return 'Face detection failed';
      case FaceAuthErrorType.userAlreadyExists:
        return 'User ID already exists';
      case FaceAuthErrorType.faceAlreadyRegistered:
        return 'Face already registered';
      case FaceAuthErrorType.registrationTimeout:
        return 'Registration timed out';
      case FaceAuthErrorType.insufficientSamples:
        return 'Insufficient samples collected';
      case FaceAuthErrorType.authenticationFailed:
        return 'Authentication failed';
      case FaceAuthErrorType.authenticationTimeout:
        return 'Authentication timed out';
      case FaceAuthErrorType.userNotFound:
        return 'User not found';
      case FaceAuthErrorType.databaseError:
        return 'Database error';
      case FaceAuthErrorType.databaseInitializationFailed:
        return 'Database initialization failed';
      case FaceAuthErrorType.modelLoadingFailed:
        return 'Model loading failed';
      case FaceAuthErrorType.embeddingGenerationFailed:
        return 'Embedding generation failed';
      case FaceAuthErrorType.predictionFailed:
        return 'Prediction failed';
      case FaceAuthErrorType.spoofingDetected:
        return 'Spoofing detected';
      case FaceAuthErrorType.insufficientLivenessData:
        return 'Insufficient liveness data';
      case FaceAuthErrorType.livenessCheckFailed:
        return 'Liveness check failed';
      case FaceAuthErrorType.photoAttackDetected:
        return 'Photo attack detected';
      case FaceAuthErrorType.screenAttackDetected:
        return 'Screen attack detected';
      case FaceAuthErrorType.operationInProgress:
        return 'Operation in progress';
      case FaceAuthErrorType.systemError:
        return 'System error';
      case FaceAuthErrorType.unknownError:
        return 'Unknown error';
    }
  }

  /// Parse error type from message string
  static FaceAuthErrorType _parseErrorType(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('camera') &&
        lowerMessage.contains('permission')) {
      return FaceAuthErrorType.cameraPermissionDenied;
    } else if (lowerMessage.contains('camera') &&
        lowerMessage.contains('initialization')) {
      return FaceAuthErrorType.cameraInitializationFailed;
    } else if (lowerMessage.contains('no face detected')) {
      return FaceAuthErrorType.noFaceDetected;
    } else if (lowerMessage.contains('multiple faces')) {
      return FaceAuthErrorType.multipleFacesDetected;
    } else if (lowerMessage.contains('user id already exists')) {
      return FaceAuthErrorType.userAlreadyExists;
    } else if (lowerMessage.contains('face already registered')) {
      return FaceAuthErrorType.faceAlreadyRegistered;
    } else if (lowerMessage.contains('timeout')) {
      return FaceAuthErrorType.registrationTimeout;
    } else if (lowerMessage.contains('authentication failed')) {
      return FaceAuthErrorType.authenticationFailed;
    } else if (lowerMessage.contains('user not found')) {
      return FaceAuthErrorType.userNotFound;
    } else if (lowerMessage.contains('database')) {
      return FaceAuthErrorType.databaseError;
    } else if (lowerMessage.contains('model')) {
      return FaceAuthErrorType.modelLoadingFailed;
    } else if (lowerMessage.contains('spoofing detected')) {
      return FaceAuthErrorType.spoofingDetected;
    } else if (lowerMessage.contains('photo attack')) {
      return FaceAuthErrorType.photoAttackDetected;
    } else if (lowerMessage.contains('screen attack')) {
      return FaceAuthErrorType.screenAttackDetected;
    } else if (lowerMessage.contains('liveness')) {
      return FaceAuthErrorType.livenessCheckFailed;
    } else if (lowerMessage.contains('operation in progress')) {
      return FaceAuthErrorType.operationInProgress;
    } else {
      return FaceAuthErrorType.unknownError;
    }
  }
}
