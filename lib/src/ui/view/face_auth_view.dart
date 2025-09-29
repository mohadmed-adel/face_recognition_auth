import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/ui/view/widgets/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaceAuthView extends StatelessWidget {
  final FaceAuthController controller;
  final double? heightRatio;
  final bool fullWidth;
  final EdgeInsets? padding;

  const FaceAuthView({
    super.key,
    required this.controller,
    this.heightRatio = 0.25, // Default to 1/4 screen height
    this.fullWidth = true,
    this.padding,
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
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;

        // Get camera aspect ratio, default to 4:3 if not available
        final cameraAspectRatio =
            ctrl.cameraService.cameraController?.value.aspectRatio ??
                (4.0 / 3.0);

        // Calculate available width (accounting for padding)
        final availableWidth = fullWidth
            ? screenWidth - (padding?.horizontal ?? 0)
            : screenWidth * 0.9; // 90% width if not full width

        // Calculate target height based on heightRatio
        final targetHeight = screenHeight * (heightRatio ?? 0.25);

        // Calculate preview dimensions maintaining aspect ratio
        double previewWidth = availableWidth;
        double previewHeight = availableWidth / cameraAspectRatio;

        // If calculated height exceeds target height, scale down
        if (previewHeight > targetHeight) {
          previewHeight = targetHeight;
          previewWidth = targetHeight * cameraAspectRatio;
        }

        // If calculated width exceeds available width, scale down
        if (previewWidth > availableWidth) {
          previewWidth = availableWidth;
          previewHeight = availableWidth / cameraAspectRatio;
        }

        return Container(
          width: fullWidth ? screenWidth : null,
          padding: padding,
          child: Center(
            child: Container(
              width: previewWidth,
              height: previewHeight,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ctrl.cameraService.cameraController != null)
                    CameraPreview(
                      ctrl.cameraService.cameraController!,
                    )
                  else
                    Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceOverlay(FaceAuthController ctrl) {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;

        // Get camera aspect ratio, default to 4:3 if not available
        final cameraAspectRatio =
            ctrl.cameraService.cameraController?.value.aspectRatio ??
                (4.0 / 3.0);

        // Calculate available width (accounting for padding)
        final availableWidth = fullWidth
            ? screenWidth - (padding?.horizontal ?? 0)
            : screenWidth * 0.9;

        // Calculate target height based on heightRatio
        final targetHeight = screenHeight * (heightRatio ?? 0.25);

        // Calculate preview dimensions maintaining aspect ratio
        double previewWidth = availableWidth;
        double previewHeight = availableWidth / cameraAspectRatio;

        // If calculated height exceeds target height, scale down
        if (previewHeight > targetHeight) {
          previewHeight = targetHeight;
          previewWidth = targetHeight * cameraAspectRatio;
        }

        // If calculated width exceeds available width, scale down
        if (previewWidth > availableWidth) {
          previewWidth = availableWidth;
          previewHeight = availableWidth / cameraAspectRatio;
        }

        return Positioned(
          left: fullWidth
              ? (padding?.left ?? 0) + (screenWidth - previewWidth) / 2
              : (screenWidth - previewWidth) / 2,
          top: (screenHeight - previewHeight) / 2,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CustomPaint(
              painter: FacePainter(
                imageSize: ctrl.imageSize ?? Size.zero,
                face: (ctrl.faces?.isNotEmpty ?? false) ? ctrl.faces![0] : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
