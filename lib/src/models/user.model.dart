import 'dart:convert';

class User {
  String id;
  List modelData;

  User({required this.id, required this.modelData});

  static User fromMap(Map<String, dynamic> user) {
    return User(
      id: user['id'].toString(),
      modelData: jsonDecode(user['model_data']),
    );
  }

  toMap() {
    return {
      "id": id,
      'model_data': jsonEncode(modelData),
    };
  }
}
