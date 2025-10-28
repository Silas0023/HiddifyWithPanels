// services/http_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/domain_service.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static String baseUrl = 'https://aa18.de'; // 替换为你的实际基础 URL
  // 初始化服务并设置动态域名
  static Future<void> initialize() async {
    baseUrl = await DomainService.fetchValidDomain();
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      print('========== GET Request Details ==========');
      print('URL: $url');
      print('Endpoint: $endpoint');
      print('Headers: $headers');
      print('==========================================');
    }

    try {
      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print('========== GET Response Details ==========');
        print('URL: $url');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('==========================================');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("GET request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during GET request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // 统一的 POST 请求方法

  // 统一的 POST 请求方法，增加 requiresHeaders 开关
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true, // 新增开关参数，默认需要 headers
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    // 始终需要 Content-Type 来发送 JSON，除非明确提供了自定义 headers
    final finalHeaders = requiresHeaders ? (headers ?? {'Content-Type': 'application/json'}) : {'Content-Type': 'application/json'};

    if (kDebugMode) {
      print('========== POST Request Details ==========');
      print('URL: $url');
      print('Endpoint: $endpoint');
      print('RequiresHeaders: $requiresHeaders');
      print('Actual Headers: $finalHeaders');
      print('Body (raw): $body');
      print('Body (JSON): ${json.encode(body)}');
      print('==========================================');
    }

    try {
      final response = await http
          .post(
            url,
            headers: finalHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print('========== POST Response Details ==========');
        print('URL: $url');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        print('===========================================');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during POST request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }

  // POST 请求方法，不包含 headers
  Future<Map<String, dynamic>> postRequestWithoutHeaders(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      print('========== POST Request (No Headers) Details ==========');
      print('URL: $url');
      print('Endpoint: $endpoint');
      print('Headers: null');
      print('Body (raw): $body');
      print('Body (JSON): ${json.encode(body)}');
      print('========================================================');
    }

    try {
      final response = await http
          .post(
            url,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print('========== POST Response (No Headers) Details ==========');
        print('URL: $url');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('========================================================');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("POST request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('========== POST Request (No Headers) Error ==========');
        print('Error during POST request without headers to $baseUrl$endpoint: $e');
        print('=====================================================');
      }
      rethrow;
    }
  }

  // POST Form 表单请求方法
  Future<Map<String, dynamic>> postFormRequest(
    String endpoint,
    Map<String, String> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    // 合并默认的 Content-Type 和自定义 headers
    final finalHeaders = {
      'Content-Type': 'application/x-www-form-urlencoded',
      ...?headers,
    };

    if (kDebugMode) {
      print('========== POST Form Request Details ==========');
      print('URL: $url');
      print('Endpoint: $endpoint');
      print('Headers: $finalHeaders');
      print('Body (form): $body');
      print('===============================================');
    }

    try {
      final response = await http
          .post(
            url,
            headers: finalHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 20)); // 设置超时时间

      if (kDebugMode) {
        print('========== POST Form Response Details ==========');
        print('URL: $url');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        print('================================================');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("POST form request to $baseUrl$endpoint failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during POST form request to $baseUrl$endpoint: $e');
      }
      rethrow;
    }
  }
}
