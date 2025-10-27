import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortcut_category.freezed.dart';
part 'shortcut_category.g.dart';

@freezed
class ShortcutCategory with _$ShortcutCategory {
  const factory ShortcutCategory({
    required String id,
    required String name,
    required String description,
  }) = _ShortcutCategory;

  factory ShortcutCategory.fromJson(Map<String, dynamic> json) =>
      _$ShortcutCategoryFromJson(json);
}

@freezed
class ShortcutCategoriesResponse with _$ShortcutCategoriesResponse {
  const factory ShortcutCategoriesResponse({
    required String status,
    required String message,
    required ShortcutCategoriesData data,
  }) = _ShortcutCategoriesResponse;

  factory ShortcutCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$ShortcutCategoriesResponseFromJson(json);
}

@freezed
class ShortcutCategoriesData with _$ShortcutCategoriesData {
  const factory ShortcutCategoriesData({
    required List<ShortcutCategory> categories,
  }) = _ShortcutCategoriesData;

  factory ShortcutCategoriesData.fromJson(Map<String, dynamic> json) =>
      _$ShortcutCategoriesDataFromJson(json);
}
