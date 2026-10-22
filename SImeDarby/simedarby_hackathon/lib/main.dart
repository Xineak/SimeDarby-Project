import 'package:flutter/material.dart';
import 'Frontend/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Convey',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.green),
      home: const LoginPage(),
    );
  }
}
