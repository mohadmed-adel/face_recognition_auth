import 'package:camera/camera.dart';
import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;

class FrameRequest {
  imglib.Image? imageCropped;
  CameraImage? image;
  final Face? face;
  final int requiredSamples;
  final String? userId;

  FrameRequest({
    this.imageCropped,
    this.image,
    required this.face,
    required this.requiredSamples,
    this.userId,
  });
}

class FrameResponse {
  final User? user;
  final bool success;
  final String? msg;

  FrameResponse({required this.user, required this.success, required this.msg});
}
