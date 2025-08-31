import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:face_recognition_auth/src/isolate/frame_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Face Recognition Auth Tests', () {
    test('FrameRequest should accept userId parameter', () {
      final request = FrameRequest(
        face: null,
        requiredSamples: 4,
        userId: 'test_user_123',
      );

      expect(request.userId, equals('test_user_123'));
      expect(request.requiredSamples, equals(4));
    });

    test('FrameRequest should work without userId for login', () {
      final request = FrameRequest(
        face: null,
        requiredSamples: 1,
      );

      expect(request.userId, isNull);
      expect(request.requiredSamples, equals(1));
    });

    test('User model should handle string ID correctly', () {
      final user = User(
        id: 'test_user_123',
        modelData: [
          [1.0, 2.0, 3.0]
        ],
      );

      expect(user.id, equals('test_user_123'));
      expect(
          user.modelData,
          equals([
            [1.0, 2.0, 3.0]
          ]));
    });

    test('DatabaseHelper should have userExists method', () {
      final db = DatabaseHelper.instance;
      expect(db.userExists, isA<Function>());
    });

    test('DatabaseHelper should have getUserById method', () {
      final db = DatabaseHelper.instance;
      expect(db.getUserById, isA<Function>());
    });

    test('DatabaseHelper should have deleteUser method', () {
      final db = DatabaseHelper.instance;
      expect(db.deleteUser, isA<Function>());
    });
  });
}
