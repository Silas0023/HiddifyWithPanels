class Plan {
  final int id;
  final String name;
  final String currentPrice; // 直接使用字符串
  final String? price;
  final String? content;
  final String? tag;
  final int sort;
  final bool? show;
  final String? appleValue;
  final String? periodType;

  Plan({
    required this.id,
    required this.name,
    required this.currentPrice,
    this.price,
    this.content,
    this.tag,
    required this.sort,
    this.show,
    this.appleValue,
    this.periodType,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // 支持驼峰和蛇形命名
    final currentPriceValue = json['currentPrice'] ?? json['current_price'] ?? '';
    final priceValue = json['price'];
    final appleValueValue = json['appleValue'] ?? json['apple_value'];
    final periodTypeValue = json['periodType'] ?? json['period_type'];

    return Plan(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name'] is String ? json['name'] as String : '未知',
      currentPrice: currentPriceValue.toString(),
      price: priceValue?.toString(),
      content: json['content'] as String?,
      tag: json['tag'] as String?,
      sort: json['sort'] is int ? json['sort'] as int : 0,
      show: json['show'] == 1 || json['show'] == true,
      appleValue: appleValueValue as String?,
      periodType: periodTypeValue as String?,
    );
  }
}
