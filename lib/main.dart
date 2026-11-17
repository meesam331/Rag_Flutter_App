import 'package:flutter/material.dart';

import 'project.dart';

void main() {
  runApp(const PagewiseApp());
}

class PagewiseApp extends StatelessWidget {
  const PagewiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagewise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6558E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        fontFamily: 'Roboto',
      ),
      home: const ProjectPage(),
    );
  }
}
