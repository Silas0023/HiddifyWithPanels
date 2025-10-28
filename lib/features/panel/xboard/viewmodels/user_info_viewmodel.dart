// viewmodels/user_info_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_info_viewmodel.g.dart';

// 使用 AsyncNotifierProvider 替代 ChangeNotifier + FutureProvider
@riverpod
class UserInfoViewModel extends _$UserInfoViewModel {
  late final UserService _userService;

  @override
  Future<UserInfo?> build() async {
    _userService = UserService();
    return fetchUserInfo();
  }

  Future<UserInfo?> fetchUserInfo() async {
    // 设置为加载状态
    state = const AsyncValue.loading();

    if (kDebugMode) {
      print('开始获取用户信息...');
    }

    try {
      final token = await getToken();
      if (token != null) {
        if (kDebugMode) {
          print('Token: $token');
        }
        final userInfo = await _userService.fetchUserInfo(token);
        if (kDebugMode) {
          print('用户信息已获取: $userInfo');
        }
        // 更新状态为成功
        state = AsyncValue.data(userInfo);
        return userInfo;
      } else {
        if (kDebugMode) {
          print('未找到Token');
        }
        state = const AsyncValue.data(null);
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('获取用户信息失败: $e');
      }
      // 更新状态为错误
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  // 刷新用户信息
  Future<void> refresh() async {
    await fetchUserInfo();
  }
}
