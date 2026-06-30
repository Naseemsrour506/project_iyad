import 'package:flutter/material.dart';

/// מודל פשוט שמייצג התראה בודדת על הודעה פוגענית.
class AlertItem {
  final String childName;
  final String message;
  final String platform;
  final String time;
  final String severity; // 'high' | 'medium' | 'low'

  const AlertItem({
    required this.childName,
    required this.message,
    required this.platform,
    required this.time,
    required this.severity,
  });
}

/// מסך 'לוח בקרה להורה' – מציג רשימת כרטיסיות עם התראות אחרונות
/// על הודעות פוגעניות שזוהו.
class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  // נתוני דמה (Mock) – בהמשך יוחלפו בנתונים מהשרת.
  static const List<AlertItem> _alerts = [
    AlertItem(
      childName: 'דניאל',
      message: 'זוהתה שפה פוגענית בהודעה נכנסת',
      platform: 'WhatsApp',
      time: 'לפני 5 דקות',
      severity: 'high',
    ),
    AlertItem(
      childName: 'דניאל',
      message: 'תוכן עם רמזים לבריונות רשת',
      platform: 'Instagram',
      time: 'לפני 40 דקות',
      severity: 'medium',
    ),
    AlertItem(
      childName: 'מאיה',
      message: 'מילות גנאי בצ׳אט קבוצתי',
      platform: 'Telegram',
      time: 'לפני שעתיים',
      severity: 'high',
    ),
    AlertItem(
      childName: 'מאיה',
      message: 'הודעה עם תוכן רגיש שדורש בדיקה',
      platform: 'TikTok',
      time: 'אתמול, 19:30',
      severity: 'low',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // עטיפה ב-RTL כדי שהממשק יוצג נכון בעברית.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('לוח בקרה להורה'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'התראות אחרונות',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  return _AlertCard(alert: _alerts[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// כרטיסייה בודדת המציגה התראה אחת.
class _AlertCard extends StatelessWidget {
  final AlertItem alert;

  const _AlertCard({required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  String get _severityLabel {
    switch (alert.severity) {
      case 'high':
        return 'חמורה';
      case 'medium':
        return 'בינונית';
      default:
        return 'נמוכה';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _severityColor.withValues(alpha: 0.15),
          child: Icon(Icons.warning_amber_rounded, color: _severityColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alert.childName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _severityLabel,
                style: TextStyle(
                  color: _severityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.message),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(alert.platform,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(alert.time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          // בהמשך: ניווט למסך פירוט ההתראה.
        },
      ),
    );
  }
}
