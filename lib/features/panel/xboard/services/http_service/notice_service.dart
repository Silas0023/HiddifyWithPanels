import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/notice_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class NoticeService {
  final HttpService _httpService = HttpService();

  // 获取通知列表
  Future<List<NoticeInfo>> getNoticeList(String accessToken) async {
    if (kDebugMode) {
      print('[NoticeService] 开始获取通知列表...');
    }

    final result = await _httpService.getRequest(
      "/hjapi/appApi/getNoticeInfo",
      headers: {
        'Authorization': accessToken,
      },
    );

    if (kDebugMode) {
      print('[NoticeService] API返回结果: $result');
    }

    if (result['code'] == 200 && result['data'] != null) {
      final List<dynamic> dataList = result['data'] as List<dynamic>;
      final notices = dataList
          .map((item) => NoticeInfo.fromJson(item as Map<String, dynamic>))
          .where((notice) => notice.show == 1) // 只显示 show=1 的通知
          .toList();

      if (kDebugMode) {
        print('[NoticeService] 解析到 ${notices.length} 条通知');
      }

      return notices;
    }

    throw Exception(result['message'] ?? '获取通知失败');
  }
}
