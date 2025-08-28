import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:face_recognition_auth/src/isolate/frame_request.dart';
import 'package:face_recognition_auth/src/isolate/ml_isolate_login.dart';
import 'package:face_recognition_auth/src/isolate/ml_isolate_register.dart';

class IsolateHelper {
  SendPort? _sendPort;
  Isolate? _isolate;
  final Completer<void> _initCompleter = Completer<void>();
  ReceivePort? _receivePort; // نخزنها علشان نقدر نقفلها بعدين

  Future<void> init({
    bool forRegister = true,
    required Uint8List interpreterBytes,
    required RootIsolateToken rootIsolateToken,
  }) async {
    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      forRegister ? mlRegisterWorkerEntry : mlLoginWorkerEntry,
      _receivePort!.sendPort,
    );

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;

        _sendPort?.send([
          interpreterBytes,
          rootIsolateToken,
        ]);

        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
      }
    });

    await _initCompleter.future;
  }

  Future<FrameResponse> sendAndWait(FrameRequest request) async {
    final responsePort = ReceivePort();
    _sendPort?.send([request, responsePort.sendPort]);

    try {
      final result = await responsePort.first as FrameResponse;
      return result;
    } finally {
      responsePort.close(); // مهم علشان ما يفضلش مفتوح
    }
  }

  void dispose() {
    try {
      _receivePort?.close(); // نقفل الـ receivePort الأساسي
      _isolate?.kill(priority: Isolate.immediate);
      _sendPort = null;
      _isolate = null;
    } catch (_) {}
  }
}
