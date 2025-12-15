// viewmodels/user_info_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_info_viewmodel.g.dart';

/// 自定义异常：用于区分认证错误和其他错误
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

/// 自定义异常：用于网络或其他可恢复错误
class FetchUserInfoException implements Exception {
  final String message;
  final dynamic originalError;
  FetchUserInfoException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

// 使用 AsyncNotifierProvider 替代 ChangeNotifier + FutureProvider
// keepAlive: true 保持 provider 活跃，避免导航时重复刷新
@Riverpod(keepAlive: true)
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

      final errorMessage = e.toString();

      // 检查是否是认证错误 (401/403)
      if (errorMessage.contains('401') || errorMessage.contains('403')) {
        // 认证失败，清除token并退出登录
        await deleteToken();
        ref.read(authProvider.notifier).state = false;

        if (kDebugMode) {
          print('[UserInfoViewModel] 认证失败(401/403)，Token已清除，用户已退出登录');
        }

        state = AsyncValue.error(
          AuthenticationException('登录已过期，请重新登录'),
          stackTrace,
        );
        return null;
      } else {
        // 其他错误（网络错误等），保留token，提示用户刷新
        if (kDebugMode) {
          print('[UserInfoViewModel] 获取信息失败，但保留Token，用户可以重试');
        }

        state = AsyncValue.error(
          FetchUserInfoException('获取用户信息失败，请检查网络后重试', e),
          stackTrace,
        );
        return null;
      }
    }
  }

  // 刷新用户信息
  Future<void> refresh() async {
    await fetchUserInfo();
  }
}
