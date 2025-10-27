import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/connection/widget/experimental_feature_notice.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/alerts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO: rewrite
class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;
    final today = DateTime.now();

    ref.listen(
      connectionNotifierProvider,
      (_, next) {
        if (next case AsyncError(:final error)) {
          CustomAlertDialog.fromErr(t.presentError(error)).show(context);
        }
        if (next case AsyncData(value: Disconnected(:final connectionFailure?))) {
          CustomAlertDialog.fromErr(t.presentError(connectionFailure)).show(context);
        }
      },
    );

    final buttonTheme = Theme.of(context).extension<ConnectionButtonTheme>()!;

    Future<bool> showExperimentalNotice() async {
      final hasExperimental = ref.read(ConfigOptions.hasExperimentalFeatures);
      final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
      if (hasExperimental && canShowNotice && context.mounted) {
        return await const ExperimentalFeatureNoticeDialog().show(context) ?? false;
      }
      return true;
    }

    return _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Disconnected()) || AsyncError() => () async {
            if (await showExperimentalNotice()) {
              return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
            }
          },
        AsyncData(value: Connected()) => () async {
            if (requiresReconnect == true && await showExperimentalNotice()) {
              return await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
            }
            return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
          },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      image: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        AsyncData(value: _) => Assets.images.disconnectNorouz,
        _ => Assets.images.disconnectNorouz,
        AsyncData(value: Disconnected()) || AsyncError() => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        blurRadius: 32,
                        spreadRadius: 0,
                        color: buttonColor.withOpacity(isDark ? 0.3 : 0.2),
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        blurRadius: 16,
                        spreadRadius: -4,
                        color: buttonColor.withOpacity(isDark ? 0.2 : 0.15),
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            width: 160,
            height: 160,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              elevation: enabled ? 4 : 0,
              color: isDark ? const Color(0xFF1E2936) : Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: enabled
                        ? buttonColor.withOpacity(isDark ? 0.4 : 0.3)
                        : (isDark ? Colors.white10 : Colors.black12),
                    width: 3,
                  ),
                ),
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  splashColor: buttonColor.withOpacity(0.2),
                  highlightColor: buttonColor.withOpacity(0.1),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: TweenAnimationBuilder(
                      tween: ColorTween(end: buttonColor),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        if (useImage) {
                          return Padding(
                            padding: const EdgeInsets.all(36),
                            child: image.image(
                              filterQuality: FilterQuality.medium,
                              opacity: enabled ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.5),
                            ),
                          );
                        } else {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            child: Assets.images.logo.svg(
                              colorFilter: ColorFilter.mode(
                                enabled ? value! : value!.withOpacity(0.5),
                                BlendMode.srcIn,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ).animate(target: enabled ? 0 : 1).scaleXY(end: .95, curve: Curves.easeOut),
          ),
        ),
        const Gap(24),
        ExcludeSemantics(
          child: AnimatedText(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              letterSpacing: 0.2,
              color: enabled
                  ? (isDark ? Colors.white : const Color(0xFF1a1a1a))
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ),
      ],
    );
  }
}
