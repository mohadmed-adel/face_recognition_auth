import 'dart:convert';

class User {
  String id;
  List modelData;

  User({this.id = "N/A", required this.modelData});

  static User fromMap(Map<String, dynamic> user) {
    return User(
      id: (jsonDecode(user['id'].toString())).toString(),
      modelData: jsonDecode(user['model_data']),
    );
  }

  toMap() {
    return {'model_data': jsonEncode(modelData)};
  }
}
