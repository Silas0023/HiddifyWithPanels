import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/connection/widget/connection_wrapper.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/shortcut/shortcut_wrapper.dart';
import 'package:hiddify/features/system_tray/widget/system_tray_wrapper.dart';
import 'package:hiddify/features/window/widget/window_wrapper.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upgrader/upgrader.dart';

bool _debugAccessibility = false;

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver, PresLogger {
  bool _hasRefreshedOnStartup = false; // 标记是否已在启动时刷新过

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 应用首次启动时刷新用户数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserDataIfLoggedIn();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 不再在 resumed 时刷新，只在首次启动时刷新
    // 如果需要在应用完全退出后重新打开时刷新，可以监听 detached/resumed 状态组合
    if (state == AppLifecycleState.detached) {
      // 应用即将完全退出，重置标记
      _hasRefreshedOnStartup = false;
    }
  }

  Future<void> _refreshUserDataIfLoggedIn() async {
    // 如果已经刷新过，跳过
    if (_hasRefreshedOnStartup) {
      return;
    }

    try {
      // 检查用户是否已登录
      final isLoggedIn = ref.read(authProvider);

      if (isLoggedIn) {
        if (kDebugMode) {
          loggy.debug('App cold start, refreshing user data for logged-in user');
        }

        // 刷新用户信息（包含套餐、余额、流量等）
        ref.read(userInfoViewModelProvider.notifier).refresh();

        // 触发订阅配置更新
        await ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger();

        if (kDebugMode) {
          loggy.debug('User data refresh completed on cold start');
        }

        // 标记已刷新
        _hasRefreshedOnStartup = true;
      }
    } catch (e) {
      if (kDebugMode) {
        loggy.warning('Failed to refresh user data on cold start: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final theme = AppTheme(themeMode, locale.preferredFontFamily);

    final upgrader = ref.watch(upgraderProvider);

    ref.listen(foregroundProfilesUpdateNotifierProvider, (_, __) {});

    return WindowWrapper(
      TrayWrapper(
        ShortcutWrapper(
          ConnectionWrapper(
            MaterialApp.router(
              routerConfig: router,
              locale: locale.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              debugShowCheckedModeBanner: false,
              themeMode: themeMode.flutterThemeMode,
              theme: theme.lightTheme(null),
              darkTheme: theme.darkTheme(null),
                  title: Constants.appName,
                  builder: (context, child) {
                    child = UpgradeAlert(
                      upgrader: upgrader,
                      navigatorKey: router.routerDelegate.navigatorKey,
                      child: child ?? const SizedBox(),
                    );
                    if (kDebugMode && _debugAccessibility) {
                      return AccessibilityTools(
                        checkFontOverflows: true,
                        child: child,
                      );
                    }
                    return child;
                  },
                ),
          ),
        ),
      ),
    );
  }
}
