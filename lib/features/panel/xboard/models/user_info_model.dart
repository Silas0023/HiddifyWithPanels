class UserInfo {
  final String email;
  final double transferEnable; // 总流量（字节）
  final double u; // 上传流量（字节）
  final double d; // 下载流量（字节）
  final int? lastLoginAt; // 允许为 null
  final int createdAt;
  final bool banned; // 账户状态, true: 被封禁, false: 正常
  final bool remindExpire;
  final bool remindTraffic;
  final int? expiredAt; // 允许为 null
  final double balance; // 消费余额
  final double commissionBalance; // 剩余佣金余额
  final int planId;
  final double? discount; // 允许为 null
  final double? commissionRate; // 允许为 null
  final String? telegramId; // 允许为 null
  final String uuid;
  final String avatarUrl;

  UserInfo({
    required this.email,
    required this.transferEnable,
    required this.u,
    required this.d,
    this.lastLoginAt,
    required this.createdAt,
    required this.banned,
    required this.remindExpire,
    required this.remindTraffic,
    this.expiredAt,
    required this.balance,
    required this.commissionBalance,
    required this.planId,
    this.discount,
    this.commissionRate,
    this.telegramId,
    required this.uuid,
    required this.avatarUrl,
  });

  // 计算已使用流量（上传+下载）
  double get usedTraffic => u + d;

  // 计算剩余流量
  double get remainingTraffic => transferEnable - usedTraffic;

  // 计算使用百分比
  double get usagePercentage =>
      transferEnable > 0 ? (usedTraffic / transferEnable * 100) : 0;

  // 计算剩余天数
  int? get remainingDays {
    if (expiredAt == null) return null;
    final expireDate = DateTime.fromMillisecondsSinceEpoch(expiredAt! * 1000);
    final now = DateTime.now();
    final difference = expireDate.difference(now);
    return difference.inDays;
  }

  // 判断是否已过期
  bool get isExpired {
    final days = remainingDays;
    return days != null && days < 0;
  }

  // 从 JSON 创建 UserInfo 实例
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      // 字符串字段，如果为 null，返回空字符串
      email: json['email'] as String? ?? '',

      // 转换为 double，如果为 null，返回 0.0
      transferEnable: (json['transfer_enable'] as num?)?.toDouble() ?? 0.0,

      // 流量使用数据
      u: (json['u'] as num?)?.toDouble() ?? 0.0,
      d: (json['d'] as num?)?.toDouble() ?? 0.0,

      // 时间字段可以为 null
      lastLoginAt: json['last_login_at'] as int?,

      // 确保 createdAt 为 int，并提供默认值
      createdAt: json['created_at'] as int? ?? 0,

      // 处理布尔值
      banned: (json['banned'] as int? ?? 0) == 1,
      remindExpire: (json['remind_expire'] as int? ?? 0) == 1,
      remindTraffic: (json['remind_traffic'] as int? ?? 0) == 1,

      // 允许 expiredAt 为 null
      expiredAt: json['expired_at'] as int?,

      // 转换 balance 为 double，并处理 null
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,

      // 转换 commissionBalance 为 double，并处理 null
      commissionBalance:
          (json['commission_balance'] as num?)?.toDouble() ?? 0.0,

      // 保证 planId 是 int，提供默认值 0
      planId: json['plan_id'] as int? ?? 0,

      // 允许 discount 和 commissionRate 为 null
      discount: (json['discount'] as num?)?.toDouble(),
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),

      // 允许 telegramId 为 null
      telegramId: json['telegram_id'] as String?,

      // uuid 和 avatarUrl，如果为 null 返回空字符串
      uuid: json['uuid'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }
}
