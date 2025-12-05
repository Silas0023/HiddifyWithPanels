import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/notice_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/notice_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notice_viewmodel.g.dart';

@Riverpod(keepAlive: true)
class NoticeViewModel extends _$NoticeViewModel {
  late final NoticeService _noticeService;

  @override
  Future<List<NoticeInfo>> build() async {
    _noticeService = NoticeService();
    return fetchNotices();
  }

  Future<List<NoticeInfo>> fetchNotices() async {
    state = const AsyncValue.loading();

    if (kDebugMode) {
      print('[NoticeViewModel] 开始获取通知列表...');
    }

    try {
      final token = await getToken();
      if (token != null) {
        final notices = await _noticeService.getNoticeList(token);
        if (kDebugMode) {
          print('[NoticeViewModel] 获取到 ${notices.length} 条通知');
        }
        state = AsyncValue.data(notices);
        return notices;
      } else {
        if (kDebugMode) {
          print('[NoticeViewModel] 未找到Token');
        }
        state = const AsyncValue.data([]);
        return [];
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[NoticeViewModel] 获取通知失败: $e');
      }
      state = AsyncValue.error(e, stackTrace);
      return [];
    }
  }

  // 刷新通知列表
  Future<void> refresh() async {
    await fetchNotices();
  }

  // 检查是否有带标签的通知（用于显示徽标）
  bool get hasImportantNotices {
    final notices = state.valueOrNull ?? [];
    return notices.any((notice) => notice.tagsList.isNotEmpty);
  }
}
