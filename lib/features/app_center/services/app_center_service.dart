import 'package:hiddify/features/app_center/models/shortcut_category.dart';
import 'package:hiddify/features/app_center/models/shortcut_item.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_center_service.g.dart';

class AppCenterService {
  final HttpService _httpService;

  AppCenterService(this._httpService);

  Future<List<ShortcutCategory>> getCategories() async {
    try {
      final response = await _httpService.getRequest(
        '/api/mobile/shortcuts/categories',
      );

      final categoriesResponse = ShortcutCategoriesResponse.fromJson(response);
      return categoriesResponse.data.categories;
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<ShortcutItem>> getShortcuts() async {
    try {
      final response = await _httpService.getRequest(
        '/api/mobile/shortcuts',
      );

      final shortcutsResponse = ShortcutsResponse.fromJson(response);
      return shortcutsResponse.data.shortcuts;
    } catch (e) {
      throw Exception('Failed to load shortcuts: $e');
    }
  }
}

@riverpod
AppCenterService appCenterService(AppCenterServiceRef ref) {
  final httpService = HttpService();
  return AppCenterService(httpService);
}

@riverpod
Future<List<ShortcutCategory>> shortcutCategories(ShortcutCategoriesRef ref) async {
  final service = ref.watch(appCenterServiceProvider);
  return service.getCategories();
}

@riverpod
Future<List<ShortcutItem>> shortcuts(ShortcutsRef ref) async {
  final service = ref.watch(appCenterServiceProvider);
  return service.getShortcuts();
}
