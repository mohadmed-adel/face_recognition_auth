import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/ui/view/widgets/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaceAuthView extends StatelessWidget {
  final FaceAuthController controller;
  final bool showSettings;
  final bool showLivenessPrompts;

  const FaceAuthView({
    super.key,
    required this.controller,
    this.showSettings = false,
    this.showLivenessPrompts = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<FaceAuthController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Camera preview
                _buildCameraPreview(ctrl),
                // Face detection overlay
                _buildFaceOverlay(ctrl),
                // Anti-spoofing UI elements
                if (showLivenessPrompts) _buildAntiSpoofingUI(ctrl, context),
                // Settings panel
                if (showSettings) _buildSettingsPanel(ctrl, context),
                // Status indicators
                _buildStatusIndicators(ctrl, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(FaceAuthController ctrl) {
    return Builder(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;

        return Transform.scale(
          scale: 1.0,
          child: AspectRatio(
            aspectRatio: MediaQuery.of(context).size.aspectRatio,
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.fitHeight,
                child: SizedBox(
                  width: width,
                  height: width *
                      (ctrl.cameraService.cameraController?.value.aspectRatio ??
                          1.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (ctrl.cameraService.cameraController != null)
                        CameraPreview(ctrl.cameraService.cameraController!),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceOverlay(FaceAuthController ctrl) {
    return Positioned.fill(
      child: CustomPaint(
        painter: FacePainter(
          imageSize: ctrl.imageSize ?? Size.zero,
          face: (ctrl.faces?.isNotEmpty ?? false) ? ctrl.faces![0] : null,
        ),
      ),
    );
  }

  Widget _buildAntiSpoofingUI(FaceAuthController ctrl, BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Liveness prompts
          if (ctrl.showLivenessPrompt) _buildLivenessPrompts(ctrl, context),
          const Spacer(),
          // Anti-spoofing status
          _buildAntiSpoofingStatus(ctrl, context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLivenessPrompts(FaceAuthController ctrl, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Liveness Detection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ctrl.livenessPrompts.map((prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prompt,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAntiSpoofingStatus(
      FaceAuthController ctrl, BuildContext context) {
    if (ctrl.antiSpoofingResult == null) return const SizedBox.shrink();

    final result = ctrl.antiSpoofingResult!;
    final isLive = result.isLive;
    final confidence = result.confidence;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLive
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isLive ? Icons.verified_user : Icons.warning,
                color: isLive ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isLive ? 'Live Person Detected' : 'Spoofing Detected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          if (result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(FaceAuthController ctrl, BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anti-Spoofing Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildConfigSelector(ctrl),
            const SizedBox(height: 16),
            _buildConfigDetails(ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSelector(FaceAuthController ctrl) {
    final configs = [
      ('Disabled', AntiSpoofingConfig.disabled()),
      ('Performance', AntiSpoofingConfig.performance()),
      ('Balanced', AntiSpoofingConfig.balanced()),
      ('High Security', AntiSpoofingConfig.highSecurity()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Level:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...configs.map((config) => RadioListTile<String>(
              title: Text(
                config.$1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              value: config.$1,
              groupValue: _getCurrentConfigName(ctrl.antiSpoofingConfig),
              onChanged: (value) {
                ctrl.configureAntiSpoofing(config.$2);
              },
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            )),
      ],
    );
  }

  Widget _buildConfigDetails(FaceAuthController ctrl) {
    final config = ctrl.antiSpoofingConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildConfigItem('Enabled', config.enabled.toString()),
        _buildConfigItem(
            'Active Liveness', config.requireActiveLiveness.toString()),
        _buildConfigItem(
            'Min Confidence', config.minConfidenceThreshold.toString()),
        _buildConfigItem('Min Frames', config.minFramesForAnalysis.toString()),
      ],
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators(FaceAuthController ctrl, BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Status: ${_getStatusText(ctrl.state)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (ctrl.faces != null) ...[
              const SizedBox(height: 4),
              Text(
                'Faces: ${ctrl.faces!.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(FaceAuthState? state) {
    switch (state) {
      case FaceAuthState.cameraOpened:
        return 'Camera Ready';
      case FaceAuthState.detectingFace:
        return 'Detecting Face';
      case FaceAuthState.collectingSamples:
        return 'Collecting Samples';
      case FaceAuthState.antiSpoofingCheck:
        return 'Anti-Spoofing Check';
      case FaceAuthState.matching:
        return 'Matching';
      case FaceAuthState.success:
        return 'Success';
      case FaceAuthState.failed:
        return 'Failed';
      case FaceAuthState.timeout:
        return 'Timeout';
      case FaceAuthState.spoofingDetected:
        return 'Spoofing Detected';
      default:
        return 'Unknown';
    }
  }

  String _getCurrentConfigName(AntiSpoofingConfig config) {
    if (config.enabled == false) return 'Disabled';
    if (config.requireActiveLiveness && config.minConfidenceThreshold >= 0.7) {
      return 'High Security';
    }
    if (config.minFramesForAnalysis <= 5) return 'Performance';
    return 'Balanced';
  }
}
