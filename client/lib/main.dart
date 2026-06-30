import 'package:flutter/material.dart';

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
      // כאן אנחנו קובעים איזה מסך יעלה ראשון
      home: const MainScreen(),
    );
  }
}

// יצירת המסך הראשון שלנו
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Kid - אפליקציית הגנה'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'ברוכים הבאים לאפליקציה!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}