import 'package:flutter/material.dart';
import 'frontend/login_page.dart'; // 引入你刚刚建的 login_page 文件

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginPage(), // 直接把首页设为你的 LoginPage
    );
  }
}
