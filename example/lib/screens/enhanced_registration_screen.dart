import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class EnhancedRegistrationScreen extends StatefulWidget {
  const EnhancedRegistrationScreen({super.key});

  @override
  State<EnhancedRegistrationScreen> createState() =>
      _EnhancedRegistrationScreenState();
}

class _EnhancedRegistrationScreenState
    extends State<EnhancedRegistrationScreen> {
  final FaceAuthController _controller = FaceAuthController();

  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  FaceAuthState? _currentState;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _generateAutoId();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready to register';
      });
      _startRegistration();
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  String _generateAutoId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _startRegistration() async {
    setState(() {});

    if (!_isInitialized) return;

    final userId = _generateAutoId();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    // Check if user already exists
    if (appState.userExists(userId)) {
      _showErrorDialog('User ID already exists. Please choose a different ID.');
      return;
    }

    setState(() {
      _statusMessage = 'Starting enhanced registration...';
    });

    try {
      // Configure enhanced anti-spoofing
      _controller.configureAntiSpoofing(AntiSpoofingConfig.lenient());

      await _controller.register(
        userId: userId,
        antiSpoofingConfig:
            AntiSpoofingConfig.lenient(), // Use lenient config for better live person detection
        onProgress: (state) {
          setState(() {
            _currentState = state;
            _statusMessage = _getStatusMessage(state);
          });
        },
        onDone: (user) {
          if (user != null) {
            appState.addUser(user);
            _showSuccessDialog('Enhanced registration successful!', user.id);
          } else {
            _showErrorDialog('Registration failed. Please try again.');
          }
        },
        onError: (error) {
          // Handle specific error types first
          if (error.type == FaceAuthErrorType.faceAlreadyRegistered) {
            _showFaceAlreadyRegisteredDialog();
          } else if (error.type == FaceAuthErrorType.cameraPermissionDenied) {
            _showPermissionDialog();
          } else if (error.type == FaceAuthErrorType.photoAttackDetected) {
            _showPhotoAttackDialog();
          } else if (error.type == FaceAuthErrorType.screenAttackDetected) {
            _showScreenAttackDialog();
          } else if (error.type == FaceAuthErrorType.spoofingDetected) {
            _showSpoofingDetectedDialog();
          } else {
            // Handle generic errors with retry option
            _showErrorDialog(
              error.userMessage,
              showTryAgain: error.isRetryable,
            );
          }
        },
      );
    } catch (e) {
      _showErrorDialog('Registration failed: $e');
    } finally {
      setState(() {});
    }
  }

  String _getStatusMessage(FaceAuthState state) {
    switch (state) {
      case FaceAuthState.cameraOpened:
        return 'Camera ready - Position your face in the frame';
      case FaceAuthState.detectingFace:
        return 'Looking for face...';
      case FaceAuthState.antiSpoofingCheck:
        return 'Verifying liveness and detecting spoofing...';
      case FaceAuthState.collectingSamples:
        return 'Collecting face samples from multiple angles...';
      case FaceAuthState.matching:
        return 'Processing face data...';
      case FaceAuthState.success:
        return 'Registration successful!';
      case FaceAuthState.failed:
        return 'Registration failed';
      case FaceAuthState.timeout:
        return 'Registration timed out';
      case FaceAuthState.spoofingDetected:
        return 'Spoofing detected - Please use a real face and move naturally';
    }
  }

  void _showSuccessDialog(String message, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text('User ID: $userId'),
            const SizedBox(height: 8),
            const Text('✅ Multi-angle capture completed'),
            const Text('✅ Anti-spoofing verification passed'),
            const Text('✅ Head movement detected'),
            const Text('✅ Live person confirmed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message, {bool showTryAgain = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (showTryAgain)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tryAgain();
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  void _showFaceAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Face Already Registered'),
        content: const Text(
          'This face is already registered in the system. '
          'Please try logging in instead, or use a different face for registration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryAgain();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to register and authenticate faces. '
          'Please enable camera permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryAgain();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showPhotoAttackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Attack Detected'),
        content: const Text(
          'A photo attack has been detected. Please use a live camera feed '
          'instead of a photo. The system requires a real, live person for registration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryAgain();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showScreenAttackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Screen Attack Detected'),
        content: const Text(
          'A screen attack has been detected. Please use a live camera feed '
          'instead of showing a photo or video on a screen. The system requires '
          'a real, live person for registration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryAgain();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showSpoofingDetectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spoofing Detected'),
        content: const Text(
          'Spoofing has been detected. Please ensure you are a real person '
          'and try again. The system requires live presence for registration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tryAgain();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Try again method to retry registration
  void _tryAgain() {
    setState(() {
      _statusMessage = 'Ready to try again...';
      _currentState = null;
    });

    // Reset the controller state
    _controller.reset();

    // Clear any error messages
    _controller.clearError();

    // Show a brief message and then allow user to start again
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Please try registration again';
        });

        // Automatically start registration again after a short delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _startRegistration();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Enhanced Registration'),
      backgroundColor: Colors.green.shade600,
      foregroundColor: Colors.white,
    ),
    body: Column(
      children: [
        // Camera Preview Section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.4, // Max 40% of screen height
                    minHeight: 200, // Minimum height
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isInitialized
                        ? FaceAuthView(controller: _controller)
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text('Initializing camera...'),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Try Again Button (shown when there's an error)
                if (_currentState == FaceAuthState.failed ||
                    _currentState == FaceAuthState.spoofingDetected ||
                    _currentState == FaceAuthState.timeout)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _tryAgain,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (_currentState == FaceAuthState.failed ||
                    _currentState == FaceAuthState.spoofingDetected ||
                    _currentState == FaceAuthState.timeout)
                  const SizedBox(height: 16),

                // Enhanced Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Enhanced Registration Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Position your face in the center of the frame\n'
                        '• Ensure good lighting and remove any masks\n'
                        '• Move your head naturally - the system will guide you\n'
                        '• Turn left, right, and look up when prompted\n'
                        '• Blink naturally and avoid holding completely still\n'
                        '• The system will capture from 4 different angles\n'
                        '• Anti-spoofing will verify you are a live person',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Color _getStatusColor() {
    switch (_currentState) {
      case FaceAuthState.cameraOpened:
        return Colors.blue;
      case FaceAuthState.detectingFace:
        return Colors.orange;
      case FaceAuthState.antiSpoofingCheck:
        return Colors.teal;
      case FaceAuthState.collectingSamples:
        return Colors.purple;
      case FaceAuthState.matching:
        return Colors.indigo;
      case FaceAuthState.success:
        return Colors.green;
      case FaceAuthState.failed:
        return Colors.red;
      case FaceAuthState.timeout:
        return Colors.red;
      case FaceAuthState.spoofingDetected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentState) {
      case FaceAuthState.cameraOpened:
        return Icons.camera_alt;
      case FaceAuthState.detectingFace:
        return Icons.face;
      case FaceAuthState.antiSpoofingCheck:
        return Icons.verified_user;
      case FaceAuthState.collectingSamples:
        return Icons.collections;
      case FaceAuthState.matching:
        return Icons.psychology;
      case FaceAuthState.success:
        return Icons.check_circle;
      case FaceAuthState.failed:
        return Icons.error;
      case FaceAuthState.timeout:
        return Icons.timer_off;
      case FaceAuthState.spoofingDetected:
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }
}
