// ml_isolate_worker.dart
import 'dart:isolate';

import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/isolate/frame_request.dart';
import 'package:flutter/services.dart';

/// Entry point for the isolate
void mlLoginWorkerEntry(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);

  MLService _mlService = MLService();
  List<List<num>> samples = [];

  port.listen((message) async {
    // ========= (١)   init =========
    if (message[0] is Uint8List) {
      final Uint8List modelBytes = message[0];
      await _mlService.initializeFromBytes(modelBytes);
      BackgroundIsolateBinaryMessenger.ensureInitialized(message[1]!);

      return;
    }

    // ========= (٢)  FrameRequest =========
    final FrameRequest request = message[0] as FrameRequest;
    final SendPort replyPort = message[1] as SendPort;

    try {
      if (request.face == null) {
        replyPort.send(
          FrameResponse(user: null, success: false, msg: 'No face detected'),
        );
        return;
      }

      if (request.image == null) return;
      _mlService.setCurrentPrediction(request.image!, request.face);
      final emb = List.from(_mlService.predictedData);
      request.image = null;
      if (emb.isEmpty) return;

      samples.add(emb.cast<num>()); //

      if (samples.length >= request.requiredSamples) {
        final centroid = _mlService.centroidFromSamples(samples);
        final user = await _mlService.predictFromEmbedding(centroid);
        if (user != null) {
          samples.clear();

          replyPort.send(
            FrameResponse(user: user, success: true, msg: 'success'),
          );
        } else {
          replyPort.send(
            FrameResponse(
              user: null,
              success: false,
              msg: 'Face not known',
            ),
          );
        }
      } else {
        replyPort.send(
          FrameResponse(
            user: null,
            success: false,
            msg: 'don\'t finish tries face required ${samples.length}',
          ),
        );
      }
    } catch (e) {
      replyPort.send(
        FrameResponse(user: null, success: false, msg: e.toString()),
      );
    }
  });
}
