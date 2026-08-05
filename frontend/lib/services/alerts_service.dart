import '../core/api_constants.dart';
import '../models/alert_model.dart';
import 'api_service.dart';
import '../models/json_parsing.dart';

class AlertsService {
  const AlertsService({required ApiService api}) : _api = api;

  final ApiService _api;

  /// `GET /api/alerts`, optionally restricted with `?unread_only=true`.
  Future<List<AlertModel>> fetchAlerts({bool unreadOnly = false}) async {
    final List<Map<String, dynamic>> json = await _api.getList(
      ApiConstants.alerts,
      query: unreadOnly ? <String, dynamic>{'unread_only': true} : null,
    );

    return json.map(AlertModel.fromJson).toList();
  }

  /// `GET /api/alerts/unread-count`.
  Future<int> fetchUnreadCount() async {
    final Map<String, dynamic> json = await _api.getObject(
      ApiConstants.unreadAlertsCount,
    );

    return parseInt(json['unread_count']);
  }

  /// `PATCH /api/alerts/{alert_id}/read` — returns the updated alert.
  Future<AlertModel> markAsRead(int alertId) async {
    return AlertModel.fromJson(
      ApiService.asObject(
        await _api.patch(ApiConstants.markAlertRead(alertId)),
      ),
    );
  }
}
