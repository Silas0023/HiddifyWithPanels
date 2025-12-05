import 'package:flutter/services.dart';

class IntercomService {
  static const MethodChannel _channel = MethodChannel('com.hiddify.app/intercom');

  /// 打开 Intercom 客服对话
  static Future<void> displayMessenger() async {
    try {
      await _channel.invokeMethod('displayMessenger');
    } on PlatformException catch (e) {
      print('Failed to open Intercom messenger: ${e.message}');
    }
  }

  /// 打开 Intercom 帮助中心
  static Future<void> displayHelpCenter() async {
    try {
      await _channel.invokeMethod('displayHelpCenter');
    } on PlatformException catch (e) {
      print('Failed to open Intercom help center: ${e.message}');
    }
  }

  /// 显示 Intercom 启动器
  static Future<void> displayLauncher() async {
    try {
      await _channel.invokeMethod('displayLauncher');
    } on PlatformException catch (e) {
      print('Failed to display Intercom launcher: ${e.message}');
    }
  }

  /// 隐藏 Intercom 启动器
  static Future<void> hideLauncher() async {
    try {
      await _channel.invokeMethod('hideLauncher');
    } on PlatformException catch (e) {
      print('Failed to hide Intercom launcher: ${e.message}');
    }
  }
}
