import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  FacePainter({required this.imageSize, required this.face});
  final Size imageSize;
  double? scaleX, scaleY;
  Face? face;
  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;

    Paint paint;
    Paint shadowPaint;

    if (face!.headEulerAngleY! > 10 || face!.headEulerAngleY! < -10) {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = Colors.red;
      shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = Colors.red.withOpacity(0.3);
    } else {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = Colors.green;
      shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = Colors.green.withOpacity(0.3);
    }

    scaleX = size.width / imageSize.width;
    scaleY = size.height / imageSize.height;

    final faceRect = _scaleRect(
        rect: face!.boundingBox,
        imageSize: imageSize,
        widgetSize: size,
        scaleX: scaleX ?? 1,
        scaleY: scaleY ?? 1);

    // Draw shadow first
    canvas.drawRRect(faceRect, shadowPaint);
    // Draw main rounded rectangle
    canvas.drawRRect(faceRect, paint);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.face != face;
  }
}

RRect _scaleRect(
    {required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    double scaleX = 1,
    double scaleY = 1}) {
  return RRect.fromLTRBR(
      (widgetSize.width - rect.left.toDouble() * scaleX),
      rect.top.toDouble() * scaleY,
      widgetSize.width - rect.right.toDouble() * scaleX,
      rect.bottom.toDouble() * scaleY,
      const Radius.circular(16));
}
