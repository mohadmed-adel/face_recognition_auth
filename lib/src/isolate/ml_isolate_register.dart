// ml_isolate_worker.dart
import 'dart:isolate';

import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/isolate/frame_request.dart';
import 'package:flutter/services.dart';

/// Entry point for the isolate
void mlRegisterWorkerEntry(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);

  MLService mlService = MLService();
  late DatabaseHelper database;
  List<List<num>> samples = [];

  port.listen((message) async {
    // ========= (١)   init =========
    if (message[0] is Uint8List) {
      final Uint8List modelBytes = message[0];
      await mlService.initializeFromBytes(modelBytes);
      BackgroundIsolateBinaryMessenger.ensureInitialized(message[1]!);
      database = DatabaseHelper.instance;
      return;
    }

    // ========= (٢)   FrameRequest =========
    FrameRequest request = message[0] as FrameRequest;
    final SendPort replyPort = message[1] as SendPort;
    try {
      if (request.face == null) {
        replyPort.send(
          FrameResponse(user: null, success: false, msg: 'No face detected'),
        );
        return;
      }
      if (request.image == null) return;
      mlService.setCurrentPrediction(request.image!, request.face);
      final emb = List.from(mlService.predictedData);
      request.image = null;

      samples.add(emb.cast<num>());
      // onProgress?.call(FaceAuthState.collectingSamples);
      if (samples.length >= request.requiredSamples) {
        final userId =
            request.userId ?? "user_${DateTime.now().millisecondsSinceEpoch}";

        // Check if user ID already exists
        final userExists = await database.userExists(userId);
        if (userExists) {
          replyPort.send(
            FrameResponse(
              user: null,
              success: false,
              msg: 'User ID already exists: $userId',
            ),
          );
          samples.clear();
          return;
        }

        // Check if face is already registered (by face embedding)
        final centroid = mlService.centroidFromSamples(samples);
        final predicted = await mlService.predictFromEmbedding(centroid);
        if (predicted != null) {
          replyPort.send(
            FrameResponse(
              user: null,
              success: false,
              msg: 'Face already registered',
            ),
          );
          samples.clear();
          return;
        }

        // Insert new user
        await database.insert(
          User(
            modelData: samples,
            id: userId,
          ),
        );

        replyPort.send(
          FrameResponse(
            user: User(modelData: samples, id: userId),
            success: true,
            msg: 'User registered successfully with ID: $userId',
          ),
        );
        samples.clear();
      } else {
        replyPort.send(
          FrameResponse(
            user: null,
            success: false,
            msg: 'no detected face required ${samples.length}',
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
