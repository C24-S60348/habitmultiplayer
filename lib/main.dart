import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Multiplayer',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 62, 83, 93),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 62, 83, 93),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
