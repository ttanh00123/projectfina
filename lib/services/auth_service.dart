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
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/utils.dart';

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
var logger = Logger();

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
      headers: Utils.buildRequestHeader(token),
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
  String? token = await AuthStorage.getToken();
  debugPrint('Token: $token', wrapWidth: 1024);
  
  if (token == null || token.isEmpty) {
    logger.d("No token found in storage");
    return null;
  }
  
  try {
    final response = await http
        .post(Uri.parse(AppConstants.LOGIN_BY_TOKEN_API),
            headers: Utils.buildRequestHeader(token),
            body: jsonEncode({'token': token}))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == StatusCode.OK) {
      var userData = json.decode(response.body);
      bool ok = userData['result'];
      if (ok) {
        UserModel user = UserModel.fromJson(userData['user']);
        await AuthStorage.saveSession(token, user);
        
        var _locale = 'vi';
        await MasterDataStore().sync(token, locale: _locale);

        //If no FCM Token available? update it
        updateFCMTokenIfNeeded(user);

        return user;
      }
    }
  } catch (e) {
    logger.e("Error during login with token: $e");
  }
  return null;
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

Future updateFCMTokenIfNeeded(UserModel user) async {
  print('FMC Token= {}'.format(user.fcmToken ?? ""));
  if (user.fcmToken == null || user.fcmToken!.isEmpty) {
    print('FMC Token is empty');
    final fcmToken = await FirebaseMessaging.instance.getToken();
    updateFCMToken(user.id, fcmToken);
  }
}
