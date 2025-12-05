// services/aes_utils.dart
import 'dart:convert';
import 'package:encrypt/encrypt.dart';

/// AES加密解密工具类
/// 使用AES-ECB模式，PKCS7填充
class AesUtils {
  // AES密钥 - 16字节
  static const String _aesKey = 'KL20250417888888';

  static final _key = Key.fromUtf8(_aesKey);
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.ecb));

  /// 检查字符串是否是Base64编码
  static bool isBase64(String str) {
    if (str.isEmpty) return false;

    // Base64字符集检查
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    if (!base64Regex.hasMatch(str)) return false;

    // 长度必须是4的倍数
    if (str.length % 4 != 0) return false;

    try {
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查字符串是否是十六进制编码
  static bool isHex(String str) {
    if (str.isEmpty) return false;
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    return hexRegex.hasMatch(str) && str.length.isEven;
  }

  /// 检查响应是否可能是加密的
  /// 加密的响应通常是纯Base64或Hex字符串，不是有效的JSON
  static bool isEncrypted(String responseBody) {
    if (responseBody.isEmpty) return false;

    // 先尝试解析为JSON，如果成功则不是加密的
    try {
      json.decode(responseBody);
      return false; // 是有效的JSON，不需要解密
    } catch (e) {
      // 不是有效的JSON，可能是加密的
    }

    // 去除可能的空白字符
    final trimmed = responseBody.trim();

    // 检查是否是Base64或Hex格式
    return isBase64(trimmed) || isHex(trimmed);
  }

  /// 解密Base64编码的加密数据
  static String decryptBase64(String base64Data) {
    try {
      final encrypted = Encrypted.fromBase64(base64Data);
      return _encrypter.decrypt(encrypted);
    } catch (e) {
      throw Exception('Base64解密失败: $e');
    }
  }

  /// 解密十六进制编码的加密数据
  static String decryptHex(String hexData) {
    try {
      final encrypted = Encrypted.fromBase16(hexData);
      return _encrypter.decrypt(encrypted);
    } catch (e) {
      throw Exception('Hex解密失败: $e');
    }
  }

  /// 自动检测编码格式并解密
  static String decryptAuto(String encryptedData) {
    final trimmed = encryptedData.trim();

    if (isBase64(trimmed)) {
      return decryptBase64(trimmed);
    } else if (isHex(trimmed)) {
      return decryptHex(trimmed);
    } else {
      throw Exception('无法识别的加密格式');
    }
  }

  /// 加密字符串并返回Base64编码
  static String encryptToBase64(String plainText) {
    final encrypted = _encrypter.encrypt(plainText);
    return encrypted.base64;
  }

  /// 加密字符串并返回十六进制编码
  static String encryptToHex(String plainText) {
    final encrypted = _encrypter.encrypt(plainText);
    return encrypted.base16;
  }

  /// 处理API响应，自动检测是否加密并解密
  /// 返回解密后的JSON Map，如果不是加密数据则直接解析返回
  static Map<String, dynamic> processResponse(String responseBody) {
    if (responseBody.isEmpty) {
      throw Exception('响应内容为空');
    }

    final trimmed = responseBody.trim();

    // 先尝试直接解析为JSON
    try {
      final decoded = json.decode(trimmed);

      // 如果解析结果是Map，直接返回
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      // 如果解析结果是String（JSON字符串），检查是否是加密数据
      if (decoded is String) {
        final content = decoded.trim();
        if (isBase64(content) || isHex(content)) {
          try {
            final decrypted = decryptAuto(content);
            return json.decode(decrypted) as Map<String, dynamic>;
          } catch (e) {
            throw Exception('解密响应失败: $e');
          }
        }
      }

      throw Exception('无法解析响应内容: 不是有效的Map');
    } catch (e) {
      if (e.toString().contains('解密响应失败') || e.toString().contains('无法解析响应内容')) {
        rethrow;
      }
      // JSON解析失败，尝试直接作为加密数据处理
    }

    // 检查是否是加密数据（不带引号的原始Base64/Hex）
    if (isBase64(trimmed) || isHex(trimmed)) {
      try {
        final decrypted = decryptAuto(trimmed);
        return json.decode(decrypted) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('解密响应失败: $e');
      }
    }

    throw Exception('无法解析响应内容');
  }
}
