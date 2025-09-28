/// Configuration class for anti-spoofing detection parameters
class AntiSpoofingConfig {
  /// Enable or disable anti-spoofing detection
  final bool enabled;

  /// Require active liveness detection (blinking, movement)
  final bool requireActiveLiveness;

  /// Minimum confidence threshold for liveness detection
  final double minConfidenceThreshold;

  /// Minimum number of frames required for analysis
  final int minFramesForAnalysis;

  /// Maximum number of frames to keep in buffer
  final int maxFramesForAnalysis;

  /// Texture analysis threshold
  final double textureThreshold;

  /// Motion detection threshold
  final double motionThreshold;

  /// Blink detection threshold
  final double blinkThreshold;

  /// Timeout for active liveness detection (seconds)
  final int activeLivenessTimeoutSeconds;

  /// Enable debug logging
  final bool enableDebugLogging;

  const AntiSpoofingConfig({
    this.enabled = true,
    this.requireActiveLiveness = false,
    this.minConfidenceThreshold = 0.5,
    this.minFramesForAnalysis = 10,
    this.maxFramesForAnalysis = 30,
    this.textureThreshold = 0.6,
    this.motionThreshold = 0.3,
    this.blinkThreshold = 0.4,
    this.activeLivenessTimeoutSeconds = 10,
    this.enableDebugLogging = false,
  });

  /// Create a high-security configuration
  factory AntiSpoofingConfig.highSecurity() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: true,
      minConfidenceThreshold: 0.7,
      minFramesForAnalysis: 15,
      maxFramesForAnalysis: 40,
      textureThreshold: 0.7,
      motionThreshold: 0.4,
      blinkThreshold: 0.3,
      activeLivenessTimeoutSeconds: 15,
      enableDebugLogging: true,
    );
  }

  /// Create a balanced configuration
  factory AntiSpoofingConfig.balanced() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: false,
      minConfidenceThreshold: 0.5,
      minFramesForAnalysis: 10,
      maxFramesForAnalysis: 30,
      textureThreshold: 0.6,
      motionThreshold: 0.3,
      blinkThreshold: 0.4,
      activeLivenessTimeoutSeconds: 10,
      enableDebugLogging: false,
    );
  }

  /// Create a performance-optimized configuration
  factory AntiSpoofingConfig.performance() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: false,
      minConfidenceThreshold: 0.4,
      minFramesForAnalysis: 5,
      maxFramesForAnalysis: 20,
      textureThreshold: 0.5,
      motionThreshold: 0.2,
      blinkThreshold: 0.5,
      activeLivenessTimeoutSeconds: 8,
      enableDebugLogging: false,
    );
  }

  /// Create a disabled configuration
  factory AntiSpoofingConfig.disabled() {
    return const AntiSpoofingConfig(
      enabled: false,
      requireActiveLiveness: false,
      minConfidenceThreshold: 0.0,
      minFramesForAnalysis: 0,
      maxFramesForAnalysis: 0,
      textureThreshold: 0.0,
      motionThreshold: 0.0,
      blinkThreshold: 0.0,
      activeLivenessTimeoutSeconds: 0,
      enableDebugLogging: false,
    );
  }

  /// Copy with new values
  AntiSpoofingConfig copyWith({
    bool? enabled,
    bool? requireActiveLiveness,
    double? minConfidenceThreshold,
    int? minFramesForAnalysis,
    int? maxFramesForAnalysis,
    double? textureThreshold,
    double? motionThreshold,
    double? blinkThreshold,
    int? activeLivenessTimeoutSeconds,
    bool? enableDebugLogging,
  }) {
    return AntiSpoofingConfig(
      enabled: enabled ?? this.enabled,
      requireActiveLiveness:
          requireActiveLiveness ?? this.requireActiveLiveness,
      minConfidenceThreshold:
          minConfidenceThreshold ?? this.minConfidenceThreshold,
      minFramesForAnalysis: minFramesForAnalysis ?? this.minFramesForAnalysis,
      maxFramesForAnalysis: maxFramesForAnalysis ?? this.maxFramesForAnalysis,
      textureThreshold: textureThreshold ?? this.textureThreshold,
      motionThreshold: motionThreshold ?? this.motionThreshold,
      blinkThreshold: blinkThreshold ?? this.blinkThreshold,
      activeLivenessTimeoutSeconds:
          activeLivenessTimeoutSeconds ?? this.activeLivenessTimeoutSeconds,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }

  @override
  String toString() {
    return 'AntiSpoofingConfig('
        'enabled: $enabled, '
        'requireActiveLiveness: $requireActiveLiveness, '
        'minConfidenceThreshold: $minConfidenceThreshold, '
        'minFramesForAnalysis: $minFramesForAnalysis, '
        'maxFramesForAnalysis: $maxFramesForAnalysis, '
        'textureThreshold: $textureThreshold, '
        'motionThreshold: $motionThreshold, '
        'blinkThreshold: $blinkThreshold, '
        'activeLivenessTimeoutSeconds: $activeLivenessTimeoutSeconds, '
        'enableDebugLogging: $enableDebugLogging'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AntiSpoofingConfig &&
        other.enabled == enabled &&
        other.requireActiveLiveness == requireActiveLiveness &&
        other.minConfidenceThreshold == minConfidenceThreshold &&
        other.minFramesForAnalysis == minFramesForAnalysis &&
        other.maxFramesForAnalysis == maxFramesForAnalysis &&
        other.textureThreshold == textureThreshold &&
        other.motionThreshold == motionThreshold &&
        other.blinkThreshold == blinkThreshold &&
        other.activeLivenessTimeoutSeconds == activeLivenessTimeoutSeconds &&
        other.enableDebugLogging == enableDebugLogging;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      requireActiveLiveness,
      minConfidenceThreshold,
      minFramesForAnalysis,
      maxFramesForAnalysis,
      textureThreshold,
      motionThreshold,
      blinkThreshold,
      activeLivenessTimeoutSeconds,
      enableDebugLogging,
    );
  }
}
