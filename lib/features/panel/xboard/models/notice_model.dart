class NoticeInfo {
  final int id;
  final String title;
  final String content;
  final int show;
  final int? sort;
  final String tags;
  final int updatedAt;
  final List<String> tagsList;
  final String createTime;

  NoticeInfo({
    required this.id,
    required this.title,
    required this.content,
    required this.show,
    this.sort,
    required this.tags,
    required this.updatedAt,
    required this.tagsList,
    required this.createTime,
  });

  // 是否有标签（用于显示徽标）
  bool get hasImportantTags => tagsList.isNotEmpty;

  factory NoticeInfo.fromJson(Map<String, dynamic> json) {
    // 解析 tagsList
    List<String> parsedTagsList = [];
    if (json['tagsList'] != null) {
      parsedTagsList = (json['tagsList'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return NoticeInfo(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      show: json['show'] as int? ?? 0,
      sort: json['sort'] as int?,
      tags: json['tags'] as String? ?? '[]',
      updatedAt: json['updatedAt'] as int? ?? json['updated_at'] as int? ?? 0,
      tagsList: parsedTagsList,
      createTime: json['createTime'] as String? ?? json['create_time'] as String? ?? '',
    );
  }
}
