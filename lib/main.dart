import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const CafeVerseApp());
}

class CafeVerseApp extends StatelessWidget {
  const CafeVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CafeVerse',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      home: const MainShell(),
    );
  }
}
