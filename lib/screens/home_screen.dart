// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:geo_entities_app/screens/map_screen.dart';
import 'package:geo_entities_app/screens/entity_list_screen.dart';
import 'package:geo_entities_app/screens/entity_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(showAppBar: false),
    const EntityListScreen(showAppBar: false),
    const EntityFormScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        elevation: 2,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'New Entry',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Overview - Map';
      case 1:
        return 'Records - List';
      case 2:
        return 'New Entry';
      default:
        return 'Geo Entities App';
    }
  }
}