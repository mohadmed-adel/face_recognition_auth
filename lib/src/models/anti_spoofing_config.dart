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
    this.requireActiveLiveness =
        false, // Changed default to false for better real face detection
    this.minConfidenceThreshold = 0.4, // Lowered from 0.6 to 0.4 for real faces
    this.minFramesForAnalysis =
        10, // Lowered from 15 to 10 for faster detection
    this.maxFramesForAnalysis =
        25, // Lowered from 35 to 25 for faster processing
    this.textureThreshold = 0.5, // Lowered from 0.7 to 0.5 for real faces
    this.motionThreshold = 0.3, // Lowered from 0.4 to 0.3 for real faces
    this.blinkThreshold = 0.4, // Increased from 0.3 to 0.4 (less sensitive)
    this.activeLivenessTimeoutSeconds = 10, // Lowered from 12 to 10
    this.enableDebugLogging = false,
  });

  /// Create a high-security configuration
  factory AntiSpoofingConfig.highSecurity() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: true,
      minConfidenceThreshold: 0.8, // Increased from 0.7 to 0.8
      minFramesForAnalysis: 20, // Increased from 15 to 20
      maxFramesForAnalysis: 45, // Increased from 40 to 45
      textureThreshold: 0.8, // Increased from 0.7 to 0.8
      motionThreshold: 0.5, // Increased from 0.4 to 0.5
      blinkThreshold: 0.2, // Decreased from 0.3 to 0.2 (more sensitive)
      activeLivenessTimeoutSeconds: 20, // Increased from 15 to 20
      enableDebugLogging: true,
    );
  }

  /// Create a balanced configuration
  factory AntiSpoofingConfig.balanced() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness:
          false, // Changed to false for better real face detection
      minConfidenceThreshold: 0.4, // Lowered from 0.6 to 0.4 for real faces
      minFramesForAnalysis: 10, // Lowered from 15 to 10 for faster detection
      maxFramesForAnalysis: 25, // Lowered from 35 to 25 for faster processing
      textureThreshold: 0.5, // Lowered from 0.7 to 0.5 for real faces
      motionThreshold: 0.3, // Lowered from 0.4 to 0.3 for real faces
      blinkThreshold: 0.4, // Increased from 0.3 to 0.4 (less sensitive)
      activeLivenessTimeoutSeconds: 10, // Lowered from 12 to 10
      enableDebugLogging: false,
    );
  }

  /// Create a performance-optimized configuration
  factory AntiSpoofingConfig.performance() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: true,
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

  /// Create a screen-attack-resistant configuration
  factory AntiSpoofingConfig.screenResistant() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: true, // Disable to focus on screen detection
      minConfidenceThreshold:
          0.3, // Lower threshold but with enhanced screen detection
      minFramesForAnalysis: 8, // Fewer frames for faster screen detection
      maxFramesForAnalysis: 20, // Smaller buffer for faster processing
      textureThreshold: 0.4, // Moderate texture requirements
      motionThreshold: 0.2, // Lower motion threshold to catch static images
      blinkThreshold: 0.5, // Less sensitive blink detection
      activeLivenessTimeoutSeconds: 10, // Shorter timeout
      enableDebugLogging: true,
    );
  }

  /// Create a configuration specifically for detecting screen attacks with hand shake
  factory AntiSpoofingConfig.handShakeResistant() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: true, // Focus on advanced screen detection
      minConfidenceThreshold: 0.25, // Lower threshold for better detection
      minFramesForAnalysis: 10, // More frames to analyze motion patterns
      maxFramesForAnalysis: 30, // Larger buffer for pattern analysis
      textureThreshold: 0.3, // Lower texture threshold to catch screen patterns
      motionThreshold: 0.15, // Lower motion threshold to catch hand shake
      blinkThreshold: 0.4, // Moderate blink sensitivity
      activeLivenessTimeoutSeconds: 15, // Longer timeout for analysis
      enableDebugLogging: true, // Enable logging for debugging
    );
  }

  /// Create a lenient configuration for better live person detection
  factory AntiSpoofingConfig.lenient() {
    return const AntiSpoofingConfig(
      enabled: true,
      requireActiveLiveness: true, // Disable active liveness for lenient mode
      minConfidenceThreshold: 0.2, // Very low threshold for live persons
      minFramesForAnalysis: 3, // Very few frames needed
      maxFramesForAnalysis: 10, // Small buffer
      textureThreshold: 0.3, // Very low texture requirements
      motionThreshold: 0.1, // Very low motion requirements
      blinkThreshold: 0.7, // Less sensitive blink detection
      activeLivenessTimeoutSeconds: 5, // Very short timeout
      enableDebugLogging: true, // Enable logging for debugging
    );
  }

  /// Create a disabled configuration
  factory AntiSpoofingConfig.disabled() {
    return const AntiSpoofingConfig(
      enabled: false,
      requireActiveLiveness: true,
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
