import 'package:face_recognition_auth/face_recognition_auth.dart';
import 'package:flutter/foundation.dart';

class AppStateProvider extends ChangeNotifier {
  List<User> _registeredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get registeredUsers => _registeredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void addUser(User user) {
    _registeredUsers.add(user);
    notifyListeners();
  }

  void removeUser(String userId) {
    _registeredUsers.removeWhere((user) => user.id == userId);
    notifyListeners();
  }

  void clearAllUsers() {
    _registeredUsers.clear();
    notifyListeners();
  }

  void updateUsers(List<User> users) {
    _registeredUsers = users;
    notifyListeners();
  }

  User? getUserById(String userId) {
    try {
      return _registeredUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  bool userExists(String userId) {
    return _registeredUsers.any((user) => user.id == userId);
  }
}
