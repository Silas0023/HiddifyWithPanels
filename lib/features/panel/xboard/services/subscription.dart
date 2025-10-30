// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/subscription_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Subscription {
  static final SubscriptionService _subscriptionService = SubscriptionService();
  // 公共方法：处理获取新订阅链接的逻辑
  static Future<void> _handleSubscription(BuildContext context, WidgetRef ref, Future<String?> Function(String) getSubscriptionLink) async {
    try {
      final t = ref.watch(translationsProvider);
      final accessToken = await getToken();
      if (accessToken == null) {
        _showSnackbar(context, t.userInfo.noAccessToken);
        return;
      }

      print('[Subscription] 开始获取新订阅链接...');
      // 获取新的订阅链接
      final newSubscriptionLink = await getSubscriptionLink(accessToken);
      print('[Subscription] 获取到的订阅链接: $newSubscriptionLink');
      if (newSubscriptionLink != null) {
        // 在删除操作之前，保存所有需要的 notifier 引用，避免删除 active profile 后 ref 失效
        final profileRepository = await ref.read(profileRepositoryProvider.future);
        final profilesOverviewNotifier = ref.read(profilesOverviewNotifierProvider.notifier);
        final addProfileNotifier = ref.read(addProfileProvider.notifier);
        final activeProfileNotifier = ref.read(activeProfileProvider.notifier);

        // 删除旧的订阅配置
        final profilesResult = await profileRepository.watchAll().first;
        final profiles = profilesResult.getOrElse((_) => []);
        for (final profile in profiles) {
          if (profile is RemoteProfileEntity) {
            await profilesOverviewNotifier.deleteProfile(profile);
          }
        }

        print('[Subscription] 准备添加新订阅: $newSubscriptionLink');
        // 添加新的订阅链接（使用之前保存的 notifier）
        await addProfileNotifier.add(newSubscriptionLink);

        // 获取新添加的配置文件并设置为活动配置文件
        final newProfilesResult = await profileRepository.watchAll().first;
        final newProfiles = newProfilesResult.getOrElse((_) => []);
        final newProfile = newProfiles.firstWhere(
          (profile) => profile is RemoteProfileEntity && profile.url == newSubscriptionLink,
          orElse: () {
            if (newProfiles.isNotEmpty) {
              return newProfiles[0];
            } else {
              throw Exception("No profiles available");
            }
          },
        );

        // 更新活跃配置文件状态（使用之前保存的 notifier）
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        activeProfileNotifier.update((_) => newProfile);

        print('[Subscription] activeProfile 已更新为新订阅配置: ${newProfile.name}');

        // 显示成功提示
        // _showSnackbar(
        //     context,
        //     getSubscriptionLink == _subscriptionService.resetSubscriptionLink
        //         ? t.userInfo.subscriptionResetSuccess
        //         : t.userInfo.subscriptionUpdateSuccess);
      }
    } catch (e, stackTrace) {
      // 检查是否是 widget disposed 错误，如果是则静默忽略
      final errorMsg = e.toString().toLowerCase();
      final isDisposedError = errorMsg.contains('disposed') ||
                              errorMsg.contains('bad state') ||
                              (errorMsg.contains('cannot use') && errorMsg.contains('ref'));

      if (kDebugMode) {
        if (isDisposedError) {
          print('========== [Subscription] Widget Disposed 错误（已忽略） ==========');
          print('错误类型: ${e.runtimeType}');
          print('错误信息: $e');
          print('是否包含 "disposed": ${errorMsg.contains('disposed')}');
          print('是否包含 "bad state": ${errorMsg.contains('bad state')}');
          print('是否包含 "cannot use" + "ref": ${errorMsg.contains('cannot use') && errorMsg.contains('ref')}');
          print('========================================');
        } else {
          print('========== [Subscription] 订阅更新错误 ==========');
          print('错误类型: ${e.runtimeType}');
          print('错误信息: $e');
          print('堆栈跟踪:');
          print(stackTrace);
          print('是否是重置订阅: ${getSubscriptionLink == _subscriptionService.resetSubscriptionLink}');
          print('========================================');
        }
      }

      // 只有在不是 disposed 错误时才显示错误提示
      if (!isDisposedError) {
        final errorMessage = getSubscriptionLink == _subscriptionService.resetSubscriptionLink
            ? "重置订阅失败: $e"
            : "更新订阅失败: $e";
        _showSnackbar(context, errorMessage);
      }
    }
  }

  // 更新订阅的方法
  static Future<void> updateSubscription(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _handleSubscription(context, ref, _subscriptionService.getSubscriptionLink);
  }

  // 重置订阅的方法
  static Future<void> resetSubscription(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _handleSubscription(
      context,
      ref,
      _subscriptionService.resetSubscriptionLink,
    );
  }

  // 显示提示信息
  static void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
