import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/landmark_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LandmarkProvider(),
      child: MaterialApp(
        title: 'Bangladesh Landmarks',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF006A4E), // Bangladesh flag green
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006A4E),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF006A4E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFF006A4E),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF006A4E),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}