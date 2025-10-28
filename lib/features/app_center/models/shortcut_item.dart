import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortcut_item.freezed.dart';
part 'shortcut_item.g.dart';

@freezed
class ShortcutItem with _$ShortcutItem {
  const factory ShortcutItem({
    required int id,
    @JsonKey(name: 'appType') required String category,
    @JsonKey(name: 'appName') required String name,
    @JsonKey(name: 'appDesc') required String description,
    @JsonKey(name: 'appIcon') required String icon,
    @JsonKey(name: 'appLink') required String link,
    @JsonKey(name: 'isUse') required String isEnabled,
    @JsonKey(name: 'appTag') String? appTag,
    @JsonKey(name: 'linkType') int? linkType,
    @JsonKey(name: 'sortNum') required int order,
    @JsonKey(name: 'isAppHome') int? isAppHome,
    @JsonKey(name: 'appHomeType') int? appHomeType,
    @Default('') String color,
  }) = _ShortcutItem;

  factory ShortcutItem.fromJson(Map<String, dynamic> json) =>
      _$ShortcutItemFromJson(json);
}

@freezed
class AppCenterResponse with _$AppCenterResponse {
  const factory AppCenterResponse({
    required int status,
    required String message,
    required List<CategoryData> data,
    required int timestamp,
  }) = _AppCenterResponse;

  factory AppCenterResponse.fromJson(Map<String, dynamic> json) =>
      _$AppCenterResponseFromJson(json);
}

@freezed
class CategoryData with _$CategoryData {
  const factory CategoryData({
    required String title,
    required int sort,
    required List<ShortcutItem> typeData,
  }) = _CategoryData;

  factory CategoryData.fromJson(Map<String, dynamic> json) =>
      _$CategoryDataFromJson(json);
}
