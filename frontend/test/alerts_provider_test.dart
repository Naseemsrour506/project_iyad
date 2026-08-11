import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/models/alert_model.dart';
import 'package:frontend/providers/alerts_provider.dart';
import 'package:frontend/services/alerts_service.dart';

/// In-memory stand-in for [AlertsService].
class FakeAlertsService implements AlertsService {
  FakeAlertsService({List<AlertModel>? alerts})
    : _alerts = alerts ?? <AlertModel>[];

  List<AlertModel> _alerts;
  ApiException? markAsReadError;
  bool? lastUnreadOnlyRequest;

  @override
  Future<List<AlertModel>> fetchAlerts({bool unreadOnly = false}) async {
    lastUnreadOnlyRequest = unreadOnly;
    return unreadOnly
        ? _alerts.where((AlertModel alert) => !alert.isRead).toList()
        : List<AlertModel>.from(_alerts);
  }

  @override
  Future<int> fetchUnreadCount() async =>
      _alerts.where((AlertModel alert) => !alert.isRead).length;

  @override
  Future<AlertModel> markAsRead(int alertId) async {
    if (markAsReadError != null) throw markAsReadError!;

    late AlertModel updated;
    _alerts = _alerts.map((AlertModel alert) {
      if (alert.alertId != alertId) return alert;
      updated = alert.copyWith(isRead: true);
      return updated;
    }).toList();

    return updated;
  }
}

AlertModel buildAlert({required int alertId, bool isRead = false}) =>
    AlertModel(
      alertId: alertId,
      childId: 1,
      messageId: alertId,
      title: 'High risk message detected',
      category: 'Bullying',
      riskLevel: 'High',
      isRead: isRead,
      createdAt: DateTime.parse('2026-07-08T14:50:00'),
    );

void main() {
  test('loads alerts and the unread count', () async {
    final FakeAlertsService service = FakeAlertsService(
      alerts: <AlertModel>[
        buildAlert(alertId: 1),
        buildAlert(alertId: 2, isRead: true),
      ],
    );
    final AlertsProvider provider = AlertsProvider(alertsService: service);

    await provider.loadAlerts();
    await provider.refreshUnreadCount();

    expect(provider.alerts.length, 2);
    expect(provider.unreadCount, 1);
    expect(provider.hasLoadedOnce, isTrue);
  });

  test(
    'marking as read updates the list and the unread count immediately',
    () async {
      final FakeAlertsService service = FakeAlertsService(
        alerts: <AlertModel>[buildAlert(alertId: 1), buildAlert(alertId: 2)],
      );
      final AlertsProvider provider = AlertsProvider(alertsService: service);

      await provider.loadAlerts();
      await provider.refreshUnreadCount();
      expect(provider.unreadCount, 2);

      final String? error = await provider.markAsRead(1);

      expect(error, isNull);
      expect(provider.unreadCount, 1);
      expect(
        provider.alerts.firstWhere((AlertModel a) => a.alertId == 1).isRead,
        isTrue,
      );
    },
  );

  test(
    'removes a read alert from the list while the unread filter is on',
    () async {
      final FakeAlertsService service = FakeAlertsService(
        alerts: <AlertModel>[buildAlert(alertId: 1), buildAlert(alertId: 2)],
      );
      final AlertsProvider provider = AlertsProvider(alertsService: service);

      await provider.setUnreadOnly(true);

      expect(service.lastUnreadOnlyRequest, isTrue);
      expect(provider.alerts.length, 2);

      await provider.markAsRead(1);

      expect(provider.alerts.length, 1);
      expect(provider.alerts.single.alertId, 2);
      expect(provider.unreadCount, 1);
    },
  );

  test('returns a Hebrew message when marking as read fails', () async {
    final FakeAlertsService service = FakeAlertsService(
      alerts: <AlertModel>[buildAlert(alertId: 1)],
    );
    service.markAsReadError = ApiException.fromResponse(404, <String, dynamic>{
      'detail': 'Alert not found',
    });
    final AlertsProvider provider = AlertsProvider(alertsService: service);

    await provider.loadAlerts();
    final String? error = await provider.markAsRead(1);

    expect(error, 'ההתראה לא נמצאה או שאינה שייכת לחשבון שלכם.');
  });

  test('reset clears every field', () async {
    final FakeAlertsService service = FakeAlertsService(
      alerts: <AlertModel>[buildAlert(alertId: 1)],
    );
    final AlertsProvider provider = AlertsProvider(alertsService: service);

    await provider.loadAlerts();
    await provider.refreshUnreadCount();
    provider.reset();

    expect(provider.alerts, isEmpty);
    expect(provider.unreadCount, 0);
    expect(provider.hasLoadedOnce, isFalse);
    expect(provider.unreadOnly, isFalse);
  });
}
