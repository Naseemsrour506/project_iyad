import '../core/api_constants.dart';
import '../core/api_exception.dart';
import '../models/dashboard_stats_model.dart';
import 'api_service.dart';

class DashboardService {
  const DashboardService({required ApiService api}) : _api = api;

  final ApiService _api;

  /// `GET /api/dashboard/stats`.
  Future<DashboardStatsModel> fetchStats() async {
    return DashboardStatsModel.fromJson(
      await _api.getObject(ApiConstants.dashboardStats),
    );
  }

  /// `GET /api/reports/export`.
  Future<String> exportReportCsv() async {
    final dynamic response = await _api.get(ApiConstants.reportsExport);

    if (response is String) {
      return response;
    }

    throw ApiException.badFormat();
  }
}
