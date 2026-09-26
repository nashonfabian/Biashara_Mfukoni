import 'package:flutter/material.dart';
import 'main_nav_shell.dart';

void main() {
  runApp(const BiasharaMfukoniApp());
}

class BiasharaMfukoniApp extends StatelessWidget {
  const BiasharaMfukoniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biashara Mfukoni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2952E3),
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainNavShell(),
    );
  }
}
