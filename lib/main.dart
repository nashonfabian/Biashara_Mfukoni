import 'package:flutter/material.dart';
import 'home_page.dart';

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
        primaryColor: const Color(0xFF4B39EF),
        useMaterial3: false,
      ),
      home: const HomePageWidget(),
    );
  }
}
