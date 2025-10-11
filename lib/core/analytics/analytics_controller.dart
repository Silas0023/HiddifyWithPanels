import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analytics_controller.g.dart';

const String enableAnalyticsPrefKey = "enable_analytics";

@Riverpod(keepAlive: true)
class AnalyticsController extends _$AnalyticsController with AppLogger {
  @override
  Future<bool> build() async {
    return _preferences.getBool(enableAnalyticsPrefKey) ?? false;
  }

  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider).requireValue;

  Future<void> enableAnalytics() async {
    if (state case AsyncData(value: final enabled)) {
      loggy.debug("analytics disabled - no crash reporting service configured");
      state = const AsyncLoading();
      if (!enabled) {
        await _preferences.setBool(enableAnalyticsPrefKey, true);
      }
      state = const AsyncData(true);
    }
  }

  Future<void> disableAnalytics() async {
    if (state case AsyncData()) {
      loggy.debug("disabling analytics");
      state = const AsyncLoading();
      await _preferences.setBool(enableAnalyticsPrefKey, false);
      state = const AsyncData(false);
    }
  }
}
