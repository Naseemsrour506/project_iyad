import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/alert_model.dart';
import '../services/alerts_service.dart';

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({required AlertsService alertsService})
    : _alertsService = alertsService;

  final AlertsService _alertsService;

  List<AlertModel> _alerts = <AlertModel>[];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  bool _unreadOnly = false;
  int _unreadCount = 0;

  List<AlertModel> get alerts => List<AlertModel>.unmodifiable(_alerts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get unreadOnly => _unreadOnly;
  int get unreadCount => _unreadCount;
  bool get isEmpty => _hasLoadedOnce && _alerts.isEmpty;

  Future<void> loadAlerts({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoadedOnce && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _alerts = await _alertsService.fetchAlerts(unreadOnly: _unreadOnly);
      _hasLoadedOnce = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'אירעה שגיאה בטעינת ההתראות.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUnreadOnly(bool value) async {
    if (_unreadOnly == value) return;

    _unreadOnly = value;
    notifyListeners();
    await loadAlerts(force: true);
  }

  /// `GET /api/alerts/unread-count`. Failures are intentionally silent: a badge
  /// that cannot refresh should not interrupt the user with an error.
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _alertsService.fetchUnreadCount();
      notifyListeners();
    } on ApiException catch (_) {
      // Keep the previous count.
    } catch (_) {
      // Keep the previous count.
    }
  }

  /// Marks an alert as read and updates both the list and the badge count.
  /// Returns null on success or a Hebrew error message on failure.
  Future<String?> markAsRead(int alertId) async {
    try {
      final AlertModel updated = await _alertsService.markAsRead(alertId);

      if (_unreadOnly) {
        // The alert no longer matches the active filter.
        _alerts = _alerts
            .where((AlertModel alert) => alert.alertId != alertId)
            .toList();
      } else {
        _alerts = _alerts
            .map(
              (AlertModel alert) => alert.alertId == alertId ? updated : alert,
            )
            .toList();
      }

      notifyListeners();
      await refreshUnreadCount();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'אירעה שגיאה בעדכון ההתראה.';
    }
  }

  void reset() {
    _alerts = <AlertModel>[];
    _isLoading = false;
    _errorMessage = null;
    _hasLoadedOnce = false;
    _unreadOnly = false;
    _unreadCount = 0;
    notifyListeners();
  }
}
