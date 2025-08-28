import 'package:camera/camera.dart';
import 'package:face_recognition_auth/src/ui/logic/face_auth_controller.dart';
import 'package:face_recognition_auth/src/ui/view/widgets/FacePainter.dart';
import 'package:face_recognition_auth/src/ui/view/widgets/face_box_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaceAuthView extends StatelessWidget {
  final FaceAuthController controller;

  const FaceAuthView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<FaceAuthController>(
        builder: (context, ctrl, _) {
          final width = MediaQuery.of(context).size.width;

          var body = Transform.scale(
            scale: 1.0,
            child: AspectRatio(
              aspectRatio: MediaQuery.of(context).size.aspectRatio,
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Container(
                    width: width,
                    height:
                        width *
                        (ctrl.cameraService.cameraController?.value.aspectRatio ?? 1.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (ctrl.cameraService.cameraController != null)
                          CameraPreview(ctrl.cameraService.cameraController!),
                        if (ctrl.cameraService.cameraController != null)
                          CustomPaint(
                            painter: FacePainter(
                              imageSize: ctrl.imageSize ?? Size.zero,
                              face: (ctrl.faces?.isNotEmpty ?? false) ? ctrl.faces![0] : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          return body;
        
        },
      ),
    );
  }
   
}
