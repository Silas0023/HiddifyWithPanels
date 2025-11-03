# 用户信息缓存设计

**日期：** 2025-11-03
**问题：** 切换菜单时（连接VPN → 区域选择 → 连接VPN）会重复刷新用户信息
**目标：** 添加缓存机制，避免频繁刷新用户信息

## 需求分析

### 用户需求
- 切换菜单时不重新加载用户信息
- 保持手动刷新功能
- 应用启动时自动加载一次

### 技术约束
- 使用内存缓存（不需要持久化）
- 仅在应用启动时刷新一次
- 支持用户手动刷新

## 设计方案

### 方案选择
采用 **Riverpod keepAlive** 方案，原因：
- ✅ 实现简单（只需添加一行注解）
- ✅ 符合 Riverpod 最佳实践
- ✅ 最小化代码改动
- ✅ 性能开销小

### 核心原理

**当前问题：**
```dart
@riverpod  // 默认 auto-dispose 模式
class UserInfoViewModel extends _$UserInfoViewModel {
  @override
  Future<UserInfo?> build() async {
    _userService = UserService();
    return fetchUserInfo();  // 每次重新订阅都会调用
  }
}
```

当 widget 取消监听（如导航离开页面）时，provider 被销毁。重新监听时，`build()` 方法再次执行，触发 API 请求。

**解决方案：**
```dart
@Riverpod(keepAlive: true)  // 保持 provider 活跃
class UserInfoViewModel extends _$UserInfoViewModel {
  @override
  Future<UserInfo?> build() async {
    _userService = UserService();
    return fetchUserInfo();  // 只在首次创建时调用
  }
}
```

使用 `keepAlive: true` 后，provider 永不销毁，`build()` 方法只在应用启动时调用一次。

### 行为变化

| 场景 | 修改前 | 修改后 |
|------|--------|--------|
| 应用启动 | 自动加载 ✅ | 自动加载 ✅ |
| 导航切换 | 重新加载 ❌ | 使用缓存 ✅ |
| 手动刷新 | 调用 refresh() ✅ | 调用 refresh() ✅ |
| 应用退出 | 数据丢失 | 数据丢失 |

### 刷新机制

**保留手动刷新功能：**
```dart
Future<void> refresh() async {
  await fetchUserInfo();
}
```

**触发场景：**
- 用户点击刷新按钮
- 购买套餐后刷新
- 其他需要更新用户信息的场景

## 实施步骤

1. 修改 `user_info_viewmodel.dart`
   - 添加 `@Riverpod(keepAlive: true)` 注解

2. 重新生成代码
   - 运行 `dart run build_runner build --delete-conflicting-outputs`

3. 测试验证
   - 测试导航切换不触发刷新
   - 测试手动刷新功能正常
   - 测试应用重启后重新加载

## 预期效果

- ✅ 减少不必要的 API 请求
- ✅ 提升应用响应速度
- ✅ 改善用户体验
- ✅ 降低服务器负载

## 注意事项

1. **内存占用：** 用户信息将持续占用内存，但数据量很小，影响可忽略
2. **数据新鲜度：** 如需实时数据，用户需手动刷新
3. **应用生命周期：** 应用退出后数据丢失，重启后重新加载

## 替代方案（未采用）

### 方案2：添加缓存检查逻辑
在 `fetchUserInfo` 中检查是否已有数据，有则返回缓存。

**优点：** 更灵活的控制
**缺点：** 需要额外的缓存状态管理，增加复杂度

### 方案3：分离缓存层
创建专门的 `CacheService` 管理缓存。

**优点：** 可扩展，支持过期时间等高级功能
**缺点：** 过度设计，当前需求不需要
