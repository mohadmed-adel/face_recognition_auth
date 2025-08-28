import 'package:flutter/material.dart';

class FaceBoxPainter extends CustomPainter {
  final List faces;
  final Size imageSize;

  FaceBoxPainter(this.faces, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var face in faces) {
      final rect = face.boundingBox;
      final scaleX = size.width / imageSize.height;
      final scaleY = size.height / imageSize.width;

      final left = rect.left * scaleX;
      final top = rect.top * scaleY;
      final right = rect.right * scaleX;
      final bottom = rect.bottom * scaleY;

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom).deflate(2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
