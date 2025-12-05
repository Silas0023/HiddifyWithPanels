import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseService _purchaseService;
  Map<String, List<Plan>> _groupedPlans = {};
  List<String> _categories = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _hasLoaded = false;

  Map<String, List<Plan>> get groupedPlans => _groupedPlans;
  List<String> get categories => _categories;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // 兼容旧的 plans getter
  List<Plan> get plans {
    final List<Plan> allPlans = [];
    _groupedPlans.forEach((_, plans) {
      allPlans.addAll(plans);
    });
    return allPlans;
  }

  PurchaseViewModel({required PurchaseService purchaseService})
      : _purchaseService = purchaseService;

  // 只在数据未加载时加载（缓存策略）
  Future<void> loadIfNeeded() async {
    if (_hasLoaded || _isLoading) return;
    await fetchPlans();
  }

  // 强制重新加载数据（用于手动刷新）
  Future<void> fetchPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groupedPlans = await _purchaseService.fetchPlanDataGrouped();
      _categories = _groupedPlans.keys.toList();
      _hasLoaded = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
