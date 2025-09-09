import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FaceAuthController _controller = FaceAuthController();

  bool _isInitialized = false;
  bool _isLoggingIn = false;
  String _statusMessage = 'Initializing...';
  FaceAuthState? _currentState;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready to authenticate';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _startLogin() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoggingIn = true;
      _statusMessage = 'Starting authentication...';
    });

    try {
      await _controller.login(
        onProgress: (state) {
          setState(() {
            _currentState = state;
            _statusMessage = _getStatusMessage(state);
          });
        },
        onDone: (user) {
          if (user != null) {
            _showSuccessDialog('Login successful!', user.id);
          } else {
            _showErrorDialog('Authentication failed. User not recognized.');
          }
        },
        onError: (error) {
          _showErrorDialog('Authentication error: $error');
        },
      );
    } catch (e) {
      _showErrorDialog('Login failed: $e');
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  String _getStatusMessage(FaceAuthState state) {
    switch (state) {
      case FaceAuthState.cameraOpened:
        return 'Camera ready - Position your face in the frame';
      case FaceAuthState.detectingFace:
        return 'Looking for face...';
      case FaceAuthState.collectingSamples:
        return 'Collecting face samples...';
      case FaceAuthState.matching:
        return 'Matching face data...';
      case FaceAuthState.success:
        return 'Authentication successful!';
      case FaceAuthState.failed:
        return 'Authentication failed';
      case FaceAuthState.timeout:
        return 'Authentication timed out';
    }
  }

  void _showSuccessDialog(String message, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('User ID: $userId'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'Please ensure you are registered and try again.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Face Authentication'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    size: 64,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Face Authentication',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position your face in front of the camera to authenticate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed:
                        _isInitialized && !_isLoggingIn ? _startLogin : null,
                    icon: _isLoggingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _isLoggingIn
                          ? 'Authenticating...'
                          : 'Start Authentication',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Camera Preview Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Camera Preview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Status Message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _getStatusColor().withOpacity(0.3)),
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

                    // Camera Preview
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _isInitialized
                              ? FaceAuthView(controller: _controller)
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Initializing camera...'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Instructions
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
                                'Authentication Tips',
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
                            '• Ensure good lighting conditions\n'
                            '• Keep your face still during authentication\n'
                            '• Make sure you are already registered',
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
