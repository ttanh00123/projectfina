import 'package:flutter/material.dart';
import 'home.dart';
import 'auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthScreen(),
      routes: {
        '/home': (_) => const Home(),
      },
    );
  }
}

