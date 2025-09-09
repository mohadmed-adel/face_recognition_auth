import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FaceAuthController _controller = FaceAuthController();
  final TextEditingController _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isInitialized = false;
  bool _isRegistering = false;
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
        _statusMessage = 'Ready to register';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _startRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isInitialized) return;

    final userId = _userIdController.text.trim();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    // Check if user already exists
    if (appState.userExists(userId)) {
      _showErrorDialog('User ID already exists. Please choose a different ID.');
      return;
    }

    setState(() {
      _isRegistering = true;
      _statusMessage = 'Starting registration...';
    });

    try {
      await _controller.register(
        userId: userId,
        onProgress: (state) {
          setState(() {
            _currentState = state;
            _statusMessage = _getStatusMessage(state);
          });
        },
        onDone: (user) {
          if (user != null) {
            appState.addUser(user);
            _showSuccessDialog('Registration successful!', user.id);
          } else {
            _showErrorDialog('Registration failed. Please try again.');
          }
        },
        onError: (error) {
          _showErrorDialog('Registration error: $error');
        },
      );
    } catch (e) {
      _showErrorDialog('Registration failed: $e');
    } finally {
      setState(() {
        _isRegistering = false;
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
        return 'Processing face data...';
      case FaceAuthState.success:
        return 'Registration successful!';
      case FaceAuthState.failed:
        return 'Registration failed';
      case FaceAuthState.timeout:
        return 'Registration timed out';
    }
  }

  void _showSuccessDialog(String message, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text('User ID: $userId'),
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

  void _showErrorDialog(String message) {
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Register New User'),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // User ID Input Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter User Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'User ID',
                        hintText: 'Enter a unique user identifier',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a user ID';
                        }
                        if (value.trim().length < 3) {
                          return 'User ID must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isInitialized && !_isRegistering
                          ? _startRegistration
                          : null,
                      icon: _isRegistering
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(
                        _isRegistering
                            ? 'Registering...'
                            : 'Start Registration',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
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
                                'Registration Instructions',
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
                            '• Ensure good lighting\n'
                            '• Keep your face still during registration\n'
                            '• The system will collect 4 face samples',
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
    _userIdController.dispose();
    super.dispose();
  }
}
