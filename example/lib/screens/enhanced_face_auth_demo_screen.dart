import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/material.dart';

/// Demo screen showing the enhanced FaceAuthView with anti-spoofing capabilities
class EnhancedFaceAuthDemoScreen extends StatefulWidget {
  const EnhancedFaceAuthDemoScreen({super.key});

  @override
  State<EnhancedFaceAuthDemoScreen> createState() =>
      _EnhancedFaceAuthDemoScreenState();
}

class _EnhancedFaceAuthDemoScreenState
    extends State<EnhancedFaceAuthDemoScreen> {
  late FaceAuthController _controller;
  bool _showSettings = false;
  bool _showLivenessPrompts = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = FaceAuthController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to initialize: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _registerUser() async {
    if (!_isInitialized) return;

    final userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';

    await _controller.register(
      userId: userId,
      samples: 3,
      onProgress: (state) {
        // Registration progress: $state
      },
      onDone: (user) {
        if (user != null) {
          _showSuccessSnackBar('Registration successful! User ID: ${user.id}');
        }
      },
      onError: (error) {
        _showErrorSnackBar('Registration failed: $error');
      },
    );
  }

  Future<void> _loginUser() async {
    if (!_isInitialized) return;

    await _controller.login(
      onProgress: (state) {
        // Login progress: $state
      },
      onDone: (user) {
        if (user != null) {
          _showSuccessSnackBar('Login successful! User ID: ${user.id}');
        }
      },
      onError: (error) {
        _showErrorSnackBar('Login failed: $error');
      },
    );
  }

  void _configureAntiSpoofing(AntiSpoofingConfig config) {
    _controller.configureAntiSpoofing(config);
    _showSuccessSnackBar('Anti-spoofing configuration updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Face Auth Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showSettings ? Icons.settings : Icons.settings_outlined,
            ),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _showLivenessPrompts ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _showLivenessPrompts = !_showLivenessPrompts;
              });
            },
          ),
        ],
      ),
      body: _isInitialized
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
      bottomNavigationBar: _isInitialized
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick configuration buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _configureAntiSpoofing(
                              AntiSpoofingConfig.performance(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Performance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _configureAntiSpoofing(
                              AntiSpoofingConfig.balanced(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Balanced'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _configureAntiSpoofing(
                              AntiSpoofingConfig.highSecurity(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('High Security'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _configureAntiSpoofing(
                              AntiSpoofingConfig.screenResistant(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Screen Resistant'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _registerUser,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loginUser,
                            icon: const Icon(Icons.login),
                            label: const Text('Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
