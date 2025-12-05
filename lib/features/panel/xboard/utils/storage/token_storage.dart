import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  final result = await prefs.setString('auth_token', token);
  if (kDebugMode) {
    print('[TokenStorage] Token stored successfully: $result');
    print('[TokenStorage] Token value: ${token.substring(0, 20)}...');
  }
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (kDebugMode) {
    if (token != null) {
      print('[TokenStorage] Token retrieved: ${token.substring(0, 20)}...');
    } else {
      print('[TokenStorage] No token found in storage');
    }
  }
  return token;
}

Future<void> deleteToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
  // 同时清除用户信息
  await deleteUserInfo();
  if (kDebugMode) {
    print('[TokenStorage] Token and user info deleted from storage');
  }
}
