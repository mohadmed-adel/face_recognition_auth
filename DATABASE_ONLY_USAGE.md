# Database-Only Operations

This document explains how to use the face recognition authentication system for database operations without initializing camera services or ML models.

## Overview

The system now supports lightweight database operations that don't require camera initialization, making it perfect for:

- Checking if users exist
- Retrieving user information
- Deleting users
- Managing user lists
- Database cleanup

## Usage Examples

### Using FaceAuthController (Recommended)

```dart
import 'package:face_recognition_auth/face_recognition_auth.dart';

class UserManagementService {
  final FaceAuthController _controller = FaceAuthController();

  /// Check if a user exists without camera initialization
  Future<bool> checkUserExists(String userId) async {
    try {
      // This will only initialize the database, not camera services
      return await _controller.userExists(userId);
    } catch (e) {
      print('Error checking user: $e');
      return false;
    }
  }

  /// Get user details without camera initialization
  Future<User?> getUserDetails(String userId) async {
    try {
      return await _controller.getUserById(userId);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Delete a user without camera initialization
  Future<bool> removeUser(String userId) async {
    try {
      final result = await _controller.deleteUser(userId);
      return result > 0; // Returns true if user was deleted
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Get all registered users without camera initialization
  Future<List<User>> getAllUsers() async {
    try {
      return await _controller.getAllUsers();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  /// Delete all users (database cleanup)
  Future<void> clearAllUsers() async {
    try {
      await _controller.deleteAllUsers();
    } catch (e) {
      print('Error clearing users: $e');
    }
  }

  /// Clean up resources when done
  void dispose() {
    _controller.dispose();
  }
}
```

### Using FaceAuth directly

```dart
import 'package:face_recognition_auth/face_recognition_auth.dart';

class DirectDatabaseService {
  final FaceAuth _faceAuth = FaceAuth();

  /// Initialize only database
  Future<void> initDatabase() async {
    await _faceAuth.initializeDatabaseOnly();
  }

  /// Check user existence
  Future<bool> userExists(String userId) async {
    return await _faceAuth.userExists(userId);
  }

  /// Get user by ID
  Future<User?> getUser(String userId) async {
    return await _faceAuth.getUserById(userId);
  }

  /// Delete user
  Future<int> deleteUser(String userId) async {
    return await _faceAuth.deleteUser(userId);
  }

  /// Get all users
  Future<List<User>> getAllUsers() async {
    return await _faceAuth.getAllUsers();
  }

  /// Clean up
  Future<void> dispose() async {
    await _faceAuth.dispose();
  }
}
```

### Using FaceAuthIsolate directly

```dart
import 'package:face_recognition_auth/face_recognition_auth.dart';

class IsolateDatabaseService {
  final FaceAuthIsolate _isolate = FaceAuthIsolate();

  /// Initialize only database
  Future<void> initDatabase() async {
    await _isolate.initializeDatabaseOnly();
  }

  /// Database operations
  Future<bool> userExists(String userId) async {
    return await _isolate.userExists(userId);
  }

  Future<User?> getUser(String userId) async {
    return await _isolate.getUserById(userId);
  }

  Future<int> deleteUser(String userId) async {
    return await _isolate.deleteUser(userId);
  }

  Future<List<User>> getAllUsers() async {
    return await _isolate.getAllUsers();
  }

  /// Clean up
  Future<void> dispose() async {
    await _isolate.dispose();
  }
}
```

## Benefits

1. **Fast Initialization**: Database operations start much faster without camera setup
2. **Resource Efficient**: No camera resources, ML models, or GPU memory usage
3. **Background Safe**: Can be used in background services or when camera is not available
4. **Lightweight**: Perfect for user management operations without face recognition
5. **Independent**: Database operations work regardless of camera permissions

## When to Use

### Use Database-Only Operations For:

- User existence checks
- User information retrieval
- User deletion
- User list management
- Database maintenance
- Background services
- Settings/preferences screens

### Use Full Initialization For:

- Face registration
- Face login/authentication
- Camera-based operations
- Real-time face detection

## Error Handling

Always wrap database operations in try-catch blocks as they may fail due to:

- Database corruption
- Insufficient permissions
- Storage issues
- Database schema changes

## Performance Notes

- Database-only initialization is typically 10-50x faster than full initialization
- Memory usage is significantly lower (no ML models loaded)
- Battery impact is minimal
- Perfect for frequent database queries
