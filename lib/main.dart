import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? username = prefs.getString('username'); // Check stored username

  runApp(MyApp(username: username));
}

class MyApp extends StatelessWidget {
  final String? username;
  MyApp({required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login & API Fetch',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: username == null ? LoginScreen() : HomeScreen(username: username!),
    );
  }
}
