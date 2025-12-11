import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/landmark.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';
  final Dio _dio = Dio();

  // Fetch all landmarks (GET)
  Future<List<Landmark>> fetchLandmarks() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Landmark.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load landmarks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching landmarks: $e');
    }
  }

  // Create a new landmark (POST)
  Future<Map<String, dynamic>> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'lat': lat.toString(),
        'lon': lon.toString(),
      });

      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: fileName,
            ),
          ),
        );
      }

      final response = await _dio.post(
        baseUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic> 
            ? response.data 
            : {'success': true, 'data': response.data};
      } else {
        throw Exception('Failed to create landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating landmark: $e');
    }
  }

  // Update an existing landmark (PUT)
  Future<Map<String, dynamic>> updateLandmark({
    required int id,
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      // For PUT requests with form data
      Map<String, dynamic> data = {
        'id': id.toString(),
        'title': title,
        'lat': lat.toString(),
        'lon': lon.toString(),
      };

      if (imageFile != null) {
        // If image is provided, use multipart
        FormData formData = FormData.fromMap({
          'id': id.toString(),
          'title': title,
          'lat': lat.toString(),
          'lon': lon.toString(),
        });

        String fileName = imageFile.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: fileName,
            ),
          ),
        );

        final response = await _dio.put(
          baseUrl,
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        if (response.statusCode == 200) {
          return response.data is Map<String, dynamic>
              ? response.data
              : {'success': true};
        }
      } else {
        // Without image, use x-www-form-urlencoded
        final response = await _dio.put(
          baseUrl,
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        );

        if (response.statusCode == 200) {
          return response.data is Map<String, dynamic>
              ? response.data
              : {'success': true};
        }
      }

      throw Exception('Failed to update landmark');
    } catch (e) {
      throw Exception('Error updating landmark: $e');
    }
  }

  // Delete a landmark (DELETE)
  Future<Map<String, dynamic>> deleteLandmark(int id) async {
    try {
      final response = await _dio.delete(
        baseUrl,
        data: {'id': id.toString()},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data
            : {'success': true};
      } else {
        throw Exception('Failed to delete landmark: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting landmark: $e');
    }
  }
}