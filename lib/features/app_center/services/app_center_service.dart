import 'package:hiddify/features/app_center/models/shortcut_category.dart';
import 'package:hiddify/features/app_center/models/shortcut_item.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_center_service.g.dart';

class AppCenterService {
  final HttpService _httpService;

  AppCenterService(this._httpService);

  Future<AppCenterData> getAppCenter() async {
    try {
      final response = await _httpService.getRequest(
        '/apiv2/clickPass/getAppCenter',
      );

      final appCenterResponse = AppCenterResponse.fromJson(response);

      // Extract categories and shortcuts from the response
      final categories = appCenterResponse.data.map((categoryData) {
        return ShortcutCategory(
          title: categoryData.title,
          sort: categoryData.sort,
        );
      }).toList();

      // Flatten all shortcuts from all categories
      final shortcuts = appCenterResponse.data
          .expand((categoryData) => categoryData.typeData)
          .toList();

      return AppCenterData(
        categories: categories,
        shortcuts: shortcuts,
        categoryDataList: appCenterResponse.data,
      );
    } catch (e) {
      throw Exception('Failed to load app center data: $e');
    }
  }
}

class AppCenterData {
  final List<ShortcutCategory> categories;
  final List<ShortcutItem> shortcuts;
  final List<CategoryData> categoryDataList;

  AppCenterData({
    required this.categories,
    required this.shortcuts,
    required this.categoryDataList,
  });
}

@riverpod
AppCenterService appCenterService(AppCenterServiceRef ref) {
  final httpService = HttpService();
  return AppCenterService(httpService);
}

// keepAlive: true 保持 provider 活跃，避免导航时重复加载
@Riverpod(keepAlive: true)
Future<AppCenterData> appCenterData(AppCenterDataRef ref) async {
  final service = ref.watch(appCenterServiceProvider);
  return service.getAppCenter();
}

@riverpod
Future<List<ShortcutCategory>> shortcutCategories(ShortcutCategoriesRef ref) async {
  final appData = await ref.watch(appCenterDataProvider.future);
  return appData.categories;
}

@riverpod
Future<List<ShortcutItem>> shortcuts(ShortcutsRef ref) async {
  final appData = await ref.watch(appCenterDataProvider.future);
  return appData.shortcuts;
}
