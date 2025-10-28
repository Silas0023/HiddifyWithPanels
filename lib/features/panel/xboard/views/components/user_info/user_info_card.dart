// views/user_info_card.dart
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(userInfoViewModelProvider);
    final t = ref.watch(translationsProvider);

    return userInfoAsync.when(
      data: (userInfo) {
        if (userInfo == null) {
          return const SizedBox(); // 如果没有数据,则返回空占位
        }
        return _buildUserInfoCard(userInfo, t);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const SizedBox(),
    );
  }

  Widget _buildUserInfoCard(UserInfo userInfo, Translations t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userInfo.avatarUrl),
        ),
        title: Text(userInfo.email),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${t.userInfo.plan}: ${userInfo.planId}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                '${t.userInfo.accountStatus}: ${userInfo.banned ? t.userInfo.banned : t.userInfo.active}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
