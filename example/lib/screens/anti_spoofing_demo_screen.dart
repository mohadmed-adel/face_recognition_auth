import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/material.dart';

class AntiSpoofingDemoScreen extends StatefulWidget {
  const AntiSpoofingDemoScreen({super.key});

  @override
  State<AntiSpoofingDemoScreen> createState() => _AntiSpoofingDemoScreenState();
}

class _AntiSpoofingDemoScreenState extends State<AntiSpoofingDemoScreen> {
  final FaceAuthController _controller = FaceAuthController();
  final TextEditingController _userIdController = TextEditingController();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing...';
  FaceAuthState? _currentState;
  AntiSpoofingConfig _currentConfig = AntiSpoofingConfig.balanced();

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
        _statusMessage = 'Ready to test anti-spoofing';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _startAntiSpoofingTest() async {
    if (!_isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Starting anti-spoofing test...';
    });

    try {
      await _controller.register(
        userId: 'anti_spoofing_test_${DateTime.now().millisecondsSinceEpoch}',
        onProgress: (state) {
          setState(() {
            _currentState = state;
            _statusMessage = _getStatusMessage(state);
          });
        },
        onDone: (user) {
          if (user != null) {
            _showSuccessDialog('Anti-spoofing test completed successfully!');
          } else {
            _showErrorDialog('Anti-spoofing test failed.');
          }
        },
        onError: (error) {
          _showErrorDialog('Anti-spoofing test error: $error');
        },
      );
    } catch (e) {
      _showErrorDialog('Anti-spoofing test failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getStatusMessage(FaceAuthState state) {
    switch (state) {
      case FaceAuthState.cameraOpened:
        return 'Camera ready - Position your face in the frame';
      case FaceAuthState.detectingFace:
        return 'Looking for face...';
      case FaceAuthState.antiSpoofingCheck:
        return 'Verifying liveness (Anti-spoofing active)...';
      case FaceAuthState.collectingSamples:
        return 'Collecting face samples...';
      case FaceAuthState.matching:
        return 'Processing face data...';
      case FaceAuthState.success:
        return 'Anti-spoofing test successful!';
      case FaceAuthState.failed:
        return 'Anti-spoofing test failed';
      case FaceAuthState.timeout:
        return 'Anti-spoofing test timed out';
      case FaceAuthState.spoofingDetected:
        return 'Spoofing detected - Anti-spoofing working correctly!';
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anti-spoofing Configuration Used:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Enabled: ${_currentConfig.enabled}'),
                  Text(
                    'Active Liveness: ${_currentConfig.requireActiveLiveness}',
                  ),
                  Text(
                    'Min Confidence: ${_currentConfig.minConfidenceThreshold}',
                  ),
                  Text('Min Frames: ${_currentConfig.minFramesForAnalysis}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        title: const Text('Test Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'This could indicate that anti-spoofing is working correctly by detecting potential spoofing attempts.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
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
      title: const Text('Anti-Spoofing Demo'),
      backgroundColor: Colors.purple.shade600,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Configuration Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Anti-Spoofing Configuration',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Configuration Cards
                _buildConfigCard(
                  'Balanced',
                  'Good balance of security and performance',
                  AntiSpoofingConfig.balanced(),
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildConfigCard(
                  'High Security',
                  'Maximum security with active liveness detection',
                  AntiSpoofingConfig.highSecurity(),
                  Colors.red,
                ),
                const SizedBox(height: 8),
                _buildConfigCard(
                  'Performance',
                  'Optimized for speed and performance',
                  AntiSpoofingConfig.performance(),
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildConfigCard(
                  'Screen Resistant',
                  'Maximum protection against screen-based attacks',
                  AntiSpoofingConfig.screenResistant(),
                  Colors.deepOrange,
                ),
                const SizedBox(height: 8),
                _buildConfigCard(
                  'Disabled',
                  'No anti-spoofing (for comparison)',
                  AntiSpoofingConfig.disabled(),
                  Colors.grey,
                ),

                const SizedBox(height: 24),

                // Test Button
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_isProcessing
                      ? _startAntiSpoofingTest
                      : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.security),
                  label: Text(
                    _isProcessing
                        ? 'Testing Anti-Spoofing...'
                        : 'Start Anti-Spoofing Test',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Camera Preview Section
          Container(
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

                // Camera Preview
                Container(
                  height: 300,
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

                const SizedBox(height: 16),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.purple.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Anti-Spoofing Test Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Try different configurations to see how they affect detection\n'
                        '• Test with real faces vs. photos/screens\n'
                        '• Observe the "Verifying liveness" step\n'
                        '• High Security mode requires blinking or movement\n'
                        '• Performance mode is faster but less secure',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildConfigCard(
    String title,
    String description,
    AntiSpoofingConfig config,
    Color color,
  ) {
    final isSelected = _currentConfig == config;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentConfig = config;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${config.minConfidenceThreshold} | '
                      'Active Liveness: ${config.requireActiveLiveness} | '
                      'Min Frames: ${config.minFramesForAnalysis}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    _userIdController.dispose();
    super.dispose();
  }
}
