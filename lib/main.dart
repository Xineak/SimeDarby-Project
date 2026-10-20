import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'auth/login_page.dart';

void main() => runApp(const ConvyApp());

class ConvyApp extends StatelessWidget {
  const ConvyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: forest));
    final rounded = GoogleFonts.fredokaTextTheme(base.textTheme).apply(
      bodyColor: forest, displayColor: forest);
    final boldRounded = rounded.copyWith(
      bodySmall: rounded.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: rounded.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: rounded.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: rounded.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: rounded.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: rounded.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: rounded.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: rounded.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: rounded.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
    return MaterialApp(
      title: 'CONVY',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: boldRounded,
        appBarTheme: AppBarTheme(
          backgroundColor: canvas,
          titleTextStyle: GoogleFonts.fredoka(
            fontSize: 20, fontWeight: FontWeight.w700, color: forest)),
      ),
      home: const LoginPage(),
    );
  }
}
