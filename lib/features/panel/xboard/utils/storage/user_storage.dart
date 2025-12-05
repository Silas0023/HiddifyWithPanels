import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _userIdKey = 'user_id';
const String _userInfoKey = 'user_info';

// 存储用户ID
Future<void> storeUserId(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_userIdKey, userId);
  if (kDebugMode) {
    print('[UserStorage] User ID stored: $userId');
  }
}

// 获取用户ID
Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt(_userIdKey);
  if (kDebugMode) {
    print('[UserStorage] User ID retrieved: $userId');
  }
  return userId;
}

// 存储完整用户信息（JSON格式）
Future<void> storeUserInfo(Map<String, dynamic> userInfo) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = json.encode(userInfo);
  await prefs.setString(_userInfoKey, jsonString);
  if (kDebugMode) {
    print('[UserStorage] User info stored');
  }
}

// 获取完整用户信息
Future<Map<String, dynamic>?> getUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(_userInfoKey);
  if (jsonString != null) {
    if (kDebugMode) {
      print('[UserStorage] User info retrieved');
    }
    return json.decode(jsonString) as Map<String, dynamic>;
  }
  if (kDebugMode) {
    print('[UserStorage] No user info found');
  }
  return null;
}

// 删除用户信息
Future<void> deleteUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_userIdKey);
  await prefs.remove(_userInfoKey);
  if (kDebugMode) {
    print('[UserStorage] User info deleted');
  }
}
