// services/plan_service.dart
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';


class PlanService {
  final HttpService _httpService = HttpService();

  // 获取按分类分组的套餐数据
  Future<Map<String, List<Plan>>> fetchPlanDataGrouped(String accessToken) async {
    final result = await _httpService.getRequest(
      "/hjapi/appApi/getPurchase",
      headers: {'Authorization': accessToken},
    );

    final Map<String, List<Plan>> groupedPlans = {};
    final data = result["data"];

    if (data is Map<String, dynamic>) {
      // 新的分组数据结构: {"基础版": [...], "专业版": [...]}
      data.forEach((category, items) {
        if (items is List) {
          final List<Plan> plans = [];
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              plans.add(Plan.fromJson(item));
            }
          }
          // 按 sort 字段排序
          plans.sort((a, b) => a.sort.compareTo(b.sort));
          groupedPlans[category] = plans;
        }
      });
    }

    return groupedPlans;
  }

  // 获取平面列表的套餐数据（兼容旧的调用方式）
  Future<List<Plan>> fetchPlanData(String accessToken) async {
    final groupedPlans = await fetchPlanDataGrouped(accessToken);
    final List<Plan> allPlans = [];
    groupedPlans.forEach((_, plans) {
      allPlans.addAll(plans);
    });
    return allPlans;
  }
}
