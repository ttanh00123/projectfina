class Session {
  static String? token;
  static int? userId;
  static String? email;

  static void setSession({required String jwt, int? id, String? mail}) {
    token = jwt;
    userId = id;
    email = mail;
  }

  static void clear() {
    token = null;
    userId = null;
    email = null;
  }
}
