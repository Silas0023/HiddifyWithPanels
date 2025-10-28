// ignore_for_file: use_build_context_synchronously

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/invite_code_service.dart';

import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class InviteCodeSection extends ConsumerWidget {
  const InviteCodeSection({super.key});

  Future<void> _generateInviteCode(BuildContext context, WidgetRef ref) async {
    final t = ref.watch(translationsProvider);
    final accessToken = await getToken();
    if (accessToken == null) {
      _showSnackbar(context, t.userInfo.noAccessToken);
      return;
    }

    try {
      final success = await InviteCodeService().generateInviteCode(accessToken);
      if (success) {
        _showSnackbar(context, t.inviteCode.generateInviteCode);
        // ignore: unused_result
        ref.refresh(inviteCodesProvider);
      } else {
        _showSnackbar(context, t.inviteCode.inviteCodeGenerateError);
      }
    } catch (e) {
      _showSnackbar(context, "${t.inviteCode.inviteCodeGenerateError}: $e");
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            FluentIcons.code_24_regular,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t.inviteCode.inviteCodeListTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _generateInviteCode(context, ref),
                      icon: const Icon(FluentIcons.add_24_filled, size: 18),
                      label: Text(t.inviteCode.generateInviteCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final inviteCodesAsync = ref.watch(inviteCodesProvider);

                    return inviteCodesAsync.when(
                      data: (inviteCodes) {
                        if (inviteCodes.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    FluentIcons.clipboard_code_24_regular,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t.inviteCode.noInviteCodes,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: inviteCodes.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final inviteCode = inviteCodes[index];
                            final fullInviteLink =
                                InviteCodeService().getInviteLink(inviteCode.code);
                            return Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[850]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    FluentIcons.ticket_diagonal_24_regular,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  inviteCode.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    FluentIcons.copy_24_regular,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: fullInviteLink),
                                    );
                                    _showSnackbar(
                                      context,
                                      '${t.inviteCode.copiedInviteCode} $fullInviteLink',
                                    );
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                FluentIcons.error_circle_24_regular,
                                size: 48,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.inviteCode.fetchInviteCodesError,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$error',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
