import 'package:flutter/material.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.ensureDefaultAccount();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Expenses Manager',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _themeProvider.themeMode,
          home: MyHomePage(
            title: 'Expenses Manager',
            themeProvider: _themeProvider,
          ),
        );
      },
    );
  }
}
