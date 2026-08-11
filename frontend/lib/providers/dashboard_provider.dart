import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required DashboardService dashboardService})
    : _dashboardService = dashboardService;

  final DashboardService _dashboardService;

  DashboardStatsModel? _stats;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;

  DashboardStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedOnce => _hasLoadedOnce;

  Future<void> loadStats({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoadedOnce && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _dashboardService.fetchStats();
      _hasLoadedOnce = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'אירעה שגיאה בטעינת הנתונים.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportReportCsv() async {
    if (_isExporting) return null;

    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _dashboardService.exportReportCsv();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'אירעה שגיאה בהורדת הדוח.';
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void reset() {
    _stats = null;
    _isLoading = false;
    _isExporting = false;
    _errorMessage = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}
