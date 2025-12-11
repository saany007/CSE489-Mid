import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mid_project/main.dart';
import 'package:mid_project/providers/landmark_provider.dart';
import 'package:mid_project/models/landmark.dart';
import 'package:mid_project/screens/home_screen.dart';
import 'package:mid_project/screens/list_screen.dart';
import 'package:mid_project/screens/form_screen.dart';

void main() {
  group('Landmark Model Tests', () {
    // Test 1: Landmark model creation
    test('Landmark creates correctly with all fields', () {
      final landmark = Landmark(
        id: 1,
        title: 'Taj Mahal',
        lat: 27.1751,
        lon: 78.0421,
        image: 'tajmahal.jpg',
      );

      expect(landmark.id, 1);
      expect(landmark.title, 'Taj Mahal');
      expect(landmark.lat, 27.1751);
      expect(landmark.lon, 78.0421);
      expect(landmark.image, 'tajmahal.jpg');
    });

    // Test 2: Landmark JSON serialization
    test('Landmark fromJson and toJson work correctly', () {
      final originalLandmark = Landmark(
        id: 1,
        title: 'Taj Mahal',
        lat: 27.1751,
        lon: 78.0421,
        image: 'tajmahal.jpg',
      );

      final json = originalLandmark.toJson();
      expect(json['id'], 1);
      expect(json['title'], 'Taj Mahal');
      expect(json['lat'], 27.1751);
      expect(json['lon'], 78.0421);

      final landmarkFromJson = Landmark.fromJson(json);
      expect(landmarkFromJson.title, originalLandmark.title);
      expect(landmarkFromJson.lat, originalLandmark.lat);
      expect(landmarkFromJson.lon, originalLandmark.lon);
    });

    // Test 3: Landmark fromJson with various data types
    test('Landmark fromJson handles various data types', () {
      // Test with string ID
      final json1 = {
        'id': '1',
        'title': 'Test',
        'lat': 20.5,
        'lon': 30.5,
      };

      final landmark1 = Landmark.fromJson(json1);
      expect(landmark1.id, 1);

      // Test with integer coordinates
      final json2 = {
        'id': 2,
        'title': 'Test',
        'lat': 20,
        'lon': 30,
      };

      final landmark2 = Landmark.fromJson(json2);
      expect(landmark2.lat, 20.0);
      expect(landmark2.lon, 30.0);
    });

    // Test 4: Landmark copyWith functionality
    test('Landmark copyWith creates correct copy', () {
      final originalLandmark = Landmark(
        id: 1,
        title: 'Original',
        lat: 20.0,
        lon: 30.0,
      );

      final updatedLandmark = originalLandmark.copyWith(
        title: 'Updated',
        lat: 25.0,
      );

      expect(updatedLandmark.title, 'Updated');
      expect(updatedLandmark.lat, 25.0);
      expect(updatedLandmark.lon, originalLandmark.lon);
      expect(updatedLandmark.id, originalLandmark.id);
    });

    // Test 5: Landmark fullImageUrl getter
    test('Landmark fullImageUrl resolves correctly', () {
      // Test with null image
      final landmark1 = Landmark(
        id: 1,
        title: 'Test',
        lat: 0,
        lon: 0,
        image: null,
      );
      expect(landmark1.fullImageUrl, isNull);

      // Test with relative path
      final landmark2 = Landmark(
        id: 2,
        title: 'Test',
        lat: 0,
        lon: 0,
        image: 'test.jpg',
      );
      expect(
        landmark2.fullImageUrl,
        'https://labs.anontech.info/cse489/t3/test.jpg',
      );

      // Test with absolute URL
      final landmark3 = Landmark(
        id: 3,
        title: 'Test',
        lat: 0,
        lon: 0,
        image: 'https://example.com/image.jpg',
      );
      expect(landmark3.fullImageUrl, 'https://example.com/image.jpg');
    });

    // Test 6: Landmark equality
    test('Two landmarks with same data are equivalent', () {
      final landmark1 = Landmark(
        id: 1,
        title: 'Sundarbans',
        lat: 21.9497,
        lon: 89.1833,
      );

      final landmark2 = Landmark(
        id: 1,
        title: 'Sundarbans',
        lat: 21.9497,
        lon: 89.1833,
      );

      expect(landmark1.title, landmark2.title);
      expect(landmark1.lat, landmark2.lat);
      expect(landmark1.lon, landmark2.lon);
    });

    // Test 7: Landmark toString method
    test('Landmark toString returns correct format', () {
      final landmark = Landmark(
        id: 1,
        title: 'Test Landmark',
        lat: 23.5,
        lon: 90.5,
      );

      final result = landmark.toString();
      expect(result.contains('Test Landmark'), true);
      expect(result.contains('23.5'), true);
      expect(result.contains('90.5'), true);
    });

    // Test 8: Landmark fromMap and toMap
    test('Landmark fromMap and toMap work correctly', () {
      final originalLandmark = Landmark(
        id: 1,
        title: 'Test',
        lat: 20.5,
        lon: 30.5,
        image: 'test.jpg',
      );

      final map = originalLandmark.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Test');

      final landmarkFromMap = Landmark.fromMap(map);
      expect(landmarkFromMap.id, originalLandmark.id);
      expect(landmarkFromMap.title, originalLandmark.title);
    });

    // Test 9: Landmark with null values
    test('Landmark handles null optional fields', () {
      final landmark = Landmark(
        id: 1,
        title: 'No Image Landmark',
        lat: 23.5,
        lon: 90.5,
        image: null,
      );

      expect(landmark.image, isNull);
      expect(landmark.fullImageUrl, isNull);
      expect(landmark.title, isNotEmpty);
    });

    // Test 10: Landmark double parsing
    test('Landmark parses double values correctly', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'lat': '23.5',
        'lon': '90.5',
      };

      final landmark = Landmark.fromJson(json);
      expect(landmark.lat, 23.5);
      expect(landmark.lon, 90.5);
      expect(landmark.lat is double, true);
      expect(landmark.lon is double, true);
    });
  });

  group('LandmarkProvider Tests', () {
    // Test 11: Provider initialization
    test('LandmarkProvider initializes correctly', () {
      final provider = LandmarkProvider();

      expect(provider.landmarks, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.isOfflineMode, false);
    });
  });

  group('App Theme Tests', () {
    // Test 12: App initialization with correct theme
    testWidgets('MyApp initializes with correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify the app title
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify primary color is set correctly
      final materialApp = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      expect(materialApp.title, 'Bangladesh Landmarks');
      expect(materialApp.theme?.primaryColor, const Color(0xFF006A4E));
    });

    // Test 13: Material design compliance
    testWidgets('App follows Material design guidelines', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify Material3 is enabled
      final materialApp = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      expect(materialApp.theme?.useMaterial3, true);
    });

    // Test 14: FloatingActionButton theme
    testWidgets('FloatingActionButton has correct color', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      expect(
        materialApp.theme?.floatingActionButtonTheme?.backgroundColor,
        const Color(0xFF006A4E),
      );
      expect(
        materialApp.theme?.floatingActionButtonTheme?.foregroundColor,
        Colors.white,
      );
    });

    // Test 15: InputDecoration theme
    testWidgets('InputDecoration has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      final inputTheme = materialApp.theme?.inputDecorationTheme;

      expect(inputTheme?.filled, true);
      expect(inputTheme?.fillColor, Colors.grey[50]);
    });

    // Test 16: CardTheme styling
    testWidgets('CardTheme has correct properties', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      expect(materialApp.theme?.cardTheme?.elevation, 4);
    });

    // Test 17: AppBar theme styling
    testWidgets('AppBar has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(AppBar), findsWidgets);
    });
  });

  group('UI Navigation Tests', () {
    // Test 18: HomeScreen displays with provider
    testWidgets('HomeScreen renders with provider', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LandmarkProvider(),
          child: const MyApp(),
        ),
      );

      // Verify HomeScreen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify BottomNavigationBar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    // Test 19: Bottom navigation icons exist
    testWidgets('Bottom navigation has correct icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LandmarkProvider(),
          child: const MyApp(),
        ),
      );

      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    // Test 20: ListScreen renders
    testWidgets('ListScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LandmarkProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: ListScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(ListScreen), findsOneWidget);
      expect(find.text('Landmark Records'), findsOneWidget);
    });
  });
}

