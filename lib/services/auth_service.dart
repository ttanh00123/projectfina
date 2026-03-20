import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:format/format.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:http_status_code/http_status_code.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/request_result.dart';
import 'package:taexpense/models/user_model.dart';
import 'package:taexpense/services/auth_storage.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/utils.dart';

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
var logger = Logger();

// Future<bool> isFirstTime() async {
//   final SharedPreferences prefs = await _prefs;
//   bool? isFirstTime = prefs.getBool("isFirstTime");
//   if (isFirstTime == null) {
//     await prefs.setBool("isFirstTime", false);
//     return true;
//   } else if (isFirstTime == false) {
//     return false;
//   }

//   return false;
// }

// Future<bool> saveUserToken(String token) async {
//   final SharedPreferences prefs = await _prefs;
//   await prefs.setString('token', token);
//   return true;
// }

// Future<String?> getUserToken() async {
//   final SharedPreferences prefs = await _prefs;
//   return prefs.getString('token');
// }

// Future<bool> saveUser(UserModel data) async {
//   final SharedPreferences prefs = await _prefs;
//   await prefs.setString("user", jsonEncode(data.toJson()));
//   return true;
// }

// Future<UserModel?> getStoredUser() async {
//   final SharedPreferences prefs = await _prefs;
//   var temp = prefs.getString('user') != null
//       ? jsonDecode(prefs.getString('user')!)
//       : null;
//   if (temp != null) {
//     return UserModel.fromJson(temp);
//   } else {
//     return null;
//   }
// }

// Future<CarModel> getUserCar() async {
//   final SharedPreferences prefs = await _prefs;
//   UserModel user = UserModel.fromJson(jsonDecode(prefs.getString('user')!));
//
//   return user.userCar;
// }

// Future<CartModel> getUserCart() async {
//   final SharedPreferences prefs = await _prefs;
//   UserModel user = UserModel.fromJson(jsonDecode(prefs.getString('user')));
//   return user.userCart;
// }

// Future<bool> logOutUser(BuildContext context, int userId) async {
//   final response = await http.post(Uri.parse(AppConstants.LOGOUT_API),
//       body: {"user_id": userId.toString()});

//   // print(response.statusCode);
//   if (response.statusCode == StatusCode.OK) {
//     final SharedPreferences prefs = await _prefs;
//     prefs.clear();
//     return true;
//   }
//   return false;
// }

Future<bool> logout(BuildContext context) async {
  Session.clear();
  AuthStorage.clear();
  return true;
}

Future updateFCMToken(userId, token) async {
  print('Update FCM Token to Backend');
  var data = {};
  data["push_noti_token"] = token;
  final response = await http.put(
      Uri.parse(AppConstants.UPDATE_FMC_TOKEN_API.format(userId)),
      headers: Utils.buildRequestHeader(AppConstants.API_TOKEN),
      body: jsonEncode(data));

  if (response.statusCode == StatusCode.OK) {
    return true;
    //   jsonMap = jsonDecode(response.body);
    //   print(jsonMap['result']);
    //   return jsonMap;
  } else {
    return false;
    //   // throw Exception('Request failed:code = ${response.statusCode}');
  }
}

Future<UserModel?> loginWithToken() async {
  try{
    final response = await http
        .post(Uri.parse(AppConstants.LOGIN_BY_TOKEN_API),
            headers: Utils.buildRequestHeader(AppConstants.API_TOKEN),
            body: jsonEncode({'token': AppConstants.API_TOKEN}))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == StatusCode.OK) {
      var userData = json.decode(response.body);
      bool ok = userData['result'];
      if (ok) {
        UserModel user = UserModel.fromJson(userData['user']);
        //If no FCM Token available? update it
        updateFCMTokenIfNeeded(user);

        await AuthStorage.saveSession(AppConstants.API_TOKEN!, user);
        return user;
      } else {
        return null;
      }
    } else {
      return null;
    }
  } catch (e) {
    logger.e("Error during login with token: $e");
    return null;
  }
}

Future<UserModel?> loginWithPassword(
    BuildContext context, String email, String password) async {
  var response = await http
      .post(
        Uri.parse(AppConstants.LOGIN_API),
        headers: {
          'Content-Type': 'application/json',
          "Access-Control-Allow-Origin": "*",
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode == StatusCode.OK) {
    var data = json.decode(response.body);
    if (data['result']) {
      UserModel user = UserModel.fromJson(data['user']);
      String token = data['token'];
      String message = data['message'];

      AuthStorage.saveSession(token, user); //Persist session to local storage
      Session.setSession(jwt: token, userData: user);

      updateFCMTokenIfNeeded(user);

      return user;
    }
  }
  return null;
}

// Future<bool> loginWithPassword(BuildContext context, String email, String password) async {
//   try{
//     final response = await http
//       .post(
//         Uri.parse(AppConstants.LOGIN_API),
//         headers: {
//           'Content-Type': 'application/json',
//           "Access-Control-Allow-Origin": "*",
//         },
//         body: jsonEncode({
//           'email': email,
//           'password':
//               password, //TODO: Do not send password in plain text in production, this is just for demo
//         }),
//       )
//       .timeout(const Duration(seconds: 10));

//       if (response.statusCode == StatusCode.OK) {
//           var result = json.decode(response.body);
//           var token = result['access_token'];
//           if (token != null && token.isNotEmpty) {
//             logger.d("Login successful, token: $token");
//             _storeSessionFromToken(token);
//             _persistToken(token);
//             return true;
//           } else {
//             logger.e("Login failed, no token received");
//             return false;
//           }
//       } else {
//         logger.e("Login failed, status code: ${response.statusCode}");
//         return false;
//       }
//   } catch (e) {
//     // Xử lý lỗi kết nối hoặc timeout
//     debugPrint("Error during login: $e");
//     return false;
//   }
// }

Future updateFCMTokenIfNeeded(UserModel user) async {
  print('FMC Token= {}'.format(user.fcmToken ?? ""));
  if (user.fcmToken == null || user.fcmToken!.isEmpty) {
    print('FMC Token is empty');
    final fcmToken = await FirebaseMessaging.instance.getToken();
    updateFCMToken(user.id, fcmToken);
  }
}

// Map<String, dynamic>? _decodeJwtPayload(String token) {
//   try {
//     final parts = token.split('.');
//     if (parts.length != 3) return null;
//     final normalized = base64Url.normalize(parts[1]);
//     final payload = utf8.decode(base64Url.decode(normalized));
//     final data = json.decode(payload);
//     if (data is Map<String, dynamic>) return data;
//     if (data is Map) return Map<String, dynamic>.from(data);
//     return null;
//   } catch (_) {
//     return null;
//   }
// }

// void _storeSessionFromToken(String token) {
//   final payload = _decodeJwtPayload(token);
//   final sub = payload?['sub']?.toString();
//   final email = payload?['email']?.toString();
//   final id = sub == null ? null : int.tryParse(sub);
//   Session.setSession(jwt: token, userData: user);
// }

// Future<void> _persistToken(String token) async {
//   final prefs = await SharedPreferences.getInstance();
//   final expiry = DateTime.now().add(const Duration(days: 90));
//   await prefs.setString('jwt_token', token);
//   await prefs.setInt('jwt_expiry', expiry.millisecondsSinceEpoch);
// }

// Future<void> _clearPersistedToken() async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.remove('jwt_token');
//   await prefs.remove('jwt_expiry');
// }

// Future<bool> tryRestoreSession() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('jwt_token');
//       final expiryMs = prefs.getInt('jwt_expiry');
//       final expiry = expiryMs == null ? null : DateTime.fromMillisecondsSinceEpoch(expiryMs);

//       final tokenValid = token != null && expiry != null && expiry.isAfter(DateTime.now());
//       if (tokenValid) {
//         _storeSessionFromToken(token!);
//         // if (!mounted) return;
//         // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
//         return true;
//       }

//       // Token missing or expired: clean up and show auth form
//       await _clearPersistedToken();
//       return false;
//     } catch (e) {
//       debugPrint("Error restoring session: $e");
//       return false;
//     }
//   }
