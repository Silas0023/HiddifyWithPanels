import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortcut_item.freezed.dart';
part 'shortcut_item.g.dart';

@freezed
class ShortcutItem with _$ShortcutItem {
  const factory ShortcutItem({
    required int id,
    required String name,
    required String description,
    required String icon,
    required String color,
    required String category,
    required int order,
    required bool isEnabled,
    required String link,
  }) = _ShortcutItem;

  factory ShortcutItem.fromJson(Map<String, dynamic> json) =>
      _$ShortcutItemFromJson(json);
}

@freezed
class ShortcutsResponse with _$ShortcutsResponse {
  const factory ShortcutsResponse({
    required String status,
    required String message,
    required ShortcutsData data,
  }) = _ShortcutsResponse;

  factory ShortcutsResponse.fromJson(Map<String, dynamic> json) =>
      _$ShortcutsResponseFromJson(json);
}

@freezed
class ShortcutsData with _$ShortcutsData {
  const factory ShortcutsData({
    required List<ShortcutItem> shortcuts,
  }) = _ShortcutsData;

  factory ShortcutsData.fromJson(Map<String, dynamic> json) =>
      _$ShortcutsDataFromJson(json);
}
