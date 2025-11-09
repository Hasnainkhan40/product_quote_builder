import 'package:flutter/material.dart';
import 'package:product_quote_builder/view/home/screen/QuoteBuilderPage.dart';

class QuoteBuilderApp extends StatefulWidget {
  const QuoteBuilderApp({super.key});

  @override
  State<QuoteBuilderApp> createState() => _QuoteBuilderAppState();
}

class _QuoteBuilderAppState extends State<QuoteBuilderApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Quote Builder',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light, // 👈 match brightness here
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark, // 👈 match brightness here
        ),
        useMaterial3: true,
      ),
      home: QuoteBuilderPage(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}
