// MODULE 1: App entry point
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const PlantationApp());
}

class PlantationApp extends StatelessWidget {
  const PlantationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Tree Plantation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
