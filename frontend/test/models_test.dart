import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/alert_model.dart';
import 'package:frontend/models/analysis_result_model.dart';
import 'package:frontend/models/child_model.dart';
import 'package:frontend/models/dashboard_stats_model.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses the documented /api/auth/me payload', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'user_id': 1,
        'full_name': 'Parent Name',
        'email': 'parent@example.com',
        'role': 'Parent',
        'created_at': '2026-07-08T14:24:15.108454',
      });

      expect(user.userId, 1);
      expect(user.fullName, 'Parent Name');
      expect(user.email, 'parent@example.com');
      expect(user.role, 'Parent');
      expect(user.createdAt, isNotNull);
      expect(user.createdAt!.year, 2026);
      expect(user.initial, 'P');
    });

    test('falls back safely on missing fields', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{});

      expect(user.userId, 0);
      expect(user.fullName, '');
      expect(user.role, 'Parent');
      expect(user.createdAt, isNull);
      expect(user.initial, '?');
    });
  });

  group('ChildModel.fromJson', () {
    test('parses the documented child payload', () {
      final ChildModel child = ChildModel.fromJson(<String, dynamic>{
        'child_id': 1,
        'parent_id': 1,
        'full_name': 'Ahmad',
        'age': 13,
        'created_at': '2026-07-08T14:30:00',
      });

      expect(child.childId, 1);
      expect(child.parentId, 1);
      expect(child.fullName, 'Ahmad');
      expect(child.age, 13);
      expect(child.createdAt, DateTime.parse('2026-07-08T14:30:00'));
    });

    test('tolerates a numeric age arriving as a string', () {
      final ChildModel child = ChildModel.fromJson(<String, dynamic>{
        'child_id': '2',
        'age': '15',
        'created_at': 'not-a-date',
      });

      expect(child.childId, 2);
      expect(child.age, 15);
      expect(child.createdAt, isNull);
    });
  });

  group('AnalysisResultModel.fromJson', () {
    test('parses the documented /api/analyze response', () {
      final AnalysisResultModel result = AnalysisResultModel.fromJson(
        <String, dynamic>{
          'message_id': 1,
          'child_id': 1,
          'message': 'אף אחד לא אוהב אותך',
          'category': 'Bullying',
          'risk_level': 'High',
          'confidence': 0.88,
          'explanation':
              'The message contains humiliating or socially harmful language.',
        },
      );

      expect(result.messageId, 1);
      expect(result.childId, 1);
      expect(result.message, 'אף אחד לא אוהב אותך');
      expect(result.category, 'Bullying');
      expect(result.riskLevel, 'High');
      expect(result.confidence, closeTo(0.88, 1e-9));
      expect(result.isHighRisk, isTrue);
    });

    test('treats an integer confidence as a double', () {
      final AnalysisResultModel result = AnalysisResultModel.fromJson(
        <String, dynamic>{'confidence': 1, 'risk_level': 'Low'},
      );

      expect(result.confidence, 1.0);
      expect(result.isHighRisk, isFalse);
    });
  });

  group('AnalyzedMessageModel.fromJson', () {
    test('parses a history entry including created_at', () {
      final AnalyzedMessageModel message =
          AnalyzedMessageModel.fromJson(<String, dynamic>{
            'message_id': 7,
            'child_id': 3,
            'message': 'שלום',
            'category': 'Normal',
            'risk_level': 'Low',
            'confidence': 0.42,
            'explanation': 'Safe message.',
            'created_at': '2026-07-08T14:40:00',
          });

      expect(message.messageId, 7);
      expect(message.childId, 3);
      expect(message.riskLevel, 'Low');
      expect(message.confidence, closeTo(0.42, 1e-9));
      expect(message.createdAt, DateTime.parse('2026-07-08T14:40:00'));
    });
  });

  group('DashboardStatsModel.fromJson', () {
    test('parses the documented stats payload', () {
      final DashboardStatsModel stats = DashboardStatsModel.fromJson(
        <String, dynamic>{
          'total_children': 1,
          'total_messages': 2,
          'risk_levels': <String, dynamic>{'Low': 1, 'Medium': 0, 'High': 1},
          'categories': <String, dynamic>{
            'Normal': 1,
            'Insult': 0,
            'Threat': 0,
            'Harassment': 0,
            'Bullying': 1,
          },
        },
      );

      expect(stats.totalChildren, 1);
      expect(stats.totalMessages, 2);
      expect(stats.lowRiskCount, 1);
      expect(stats.mediumRiskCount, 0);
      expect(stats.highRiskCount, 1);
      expect(stats.categoryCount('Bullying'), 1);
      expect(stats.categoryCount('Normal'), 1);
      expect(stats.categoryCount('Unknown'), 0);
    });

    test('returns zeroes when the maps are missing', () {
      final DashboardStatsModel stats = DashboardStatsModel.fromJson(
        <String, dynamic>{},
      );

      expect(stats.totalChildren, 0);
      expect(stats.totalMessages, 0);
      expect(stats.riskLevels, isEmpty);
      expect(stats.categories, isEmpty);
      expect(stats.highRiskCount, 0);
    });
  });

  group('AlertModel.fromJson', () {
    test('parses the documented alert payload', () {
      final AlertModel alert = AlertModel.fromJson(<String, dynamic>{
        'alert_id': 1,
        'child_id': 1,
        'message_id': 1,
        'title': 'High risk message detected',
        'category': 'Bullying',
        'risk_level': 'High',
        'is_read': false,
        'created_at': '2026-07-08T14:50:00',
      });

      expect(alert.alertId, 1);
      expect(alert.messageId, 1);
      expect(alert.title, 'High risk message detected');
      expect(alert.isRead, isFalse);
      expect(alert.createdAt, DateTime.parse('2026-07-08T14:50:00'));
    });

    test('copyWith flips the read flag without touching other fields', () {
      final AlertModel alert = AlertModel.fromJson(<String, dynamic>{
        'alert_id': 4,
        'child_id': 2,
        'is_read': false,
        'title': 'High risk message detected',
      });

      final AlertModel read = alert.copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.alertId, 4);
      expect(read.childId, 2);
      expect(read.title, alert.title);
    });
  });
}
