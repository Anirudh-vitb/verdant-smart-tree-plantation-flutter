// MODULE 1: Main (app starts here)
import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Smart Tree Plantation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: HomeScreen(),
    ),
  );
}
