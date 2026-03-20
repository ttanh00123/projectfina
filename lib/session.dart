import 'package:taexpense/models/user_model.dart';

class Session {
  static String? token;
  static UserModel? user;

  static void setSession({required String jwt, UserModel? userData}) {
    token = jwt;
    user = userData;
  }

  static void clear() {
    token = null;
    user = null;
  }
}
