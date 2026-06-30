import 'package:flutter/material.dart';
import 'screens/parent/parent_dashboard.dart';

void main() {
  runApp(const SafeKidApp());
}

class SafeKidApp extends StatelessWidget {
  const SafeKidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Kid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // מסך הפתיחה: לוח הבקרה להורה
      home: const ParentDashboard(),
    );
  }
}
