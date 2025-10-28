import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortcut_category.freezed.dart';
part 'shortcut_category.g.dart';

@freezed
class ShortcutCategory with _$ShortcutCategory {
  const factory ShortcutCategory({
    required String title,
    required int sort,
  }) = _ShortcutCategory;

  factory ShortcutCategory.fromJson(Map<String, dynamic> json) =>
      _$ShortcutCategoryFromJson(json);
}
