// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geo_entities_app/models/entity.dart';
import 'package:http_parser/http_parser.dart'; // REQUIRED for MediaType

const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';
const String imageBaseUrl = 'https://labs.anontech.info/cse489/t3/';

class ApiService {
  /// GET entities
  Future<List<Entity>> getEntities() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;
      if (body.trim().isEmpty) return [];
      
      dynamic decoded;
      try {
        decoded = json.decode(body);
      } catch (e) {
        throw Exception('Failed to parse JSON: $e');
      }

      List<dynamic> listData = [];
      if (decoded is List) {
        listData = decoded;
      } else if (decoded is Map) {
        if (decoded['data'] is List) {
          listData = decoded['data'];
        } else if (decoded['entities'] is List) {
          listData = decoded['entities'];
        } else {
          final firstArray = decoded.values.firstWhere(
            (v) => v is List,
            orElse: () => null,
          );
          if (firstArray is List) {
            listData = firstArray;
          } else if (decoded.containsKey('id') || decoded.containsKey('title')) {
            listData = [decoded];
          } else {
            return [];
          }
        }
      } else {
        return [];
      }

      final entities = listData
          .map((e) => Entity.fromJson(e as Map<String, dynamic>))
          .where((ent) => ent.isValid())
          .toList();

      return entities;
    } else {
      throw Exception('Failed to load entities: ${response.statusCode}');
    }
  }

  /// CREATE entity
  Future<int> createEntity(Entity entity, File? imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    
    request.fields['title'] = entity.title;
    request.fields['lat'] = entity.lat.toString();
    request.fields['lon'] = entity.lon.toString();
    
    if (imageFile != null) {
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), 
      );
      request.files.add(multipartFile);
    }
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data.containsKey('id')) {
            return int.parse(data['id'].toString());
          }
          return -1;
        } catch (_) {
          return -1;
        }
      } else {
        throw Exception('Failed to create entity: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating entity: $e');
    }
  }

  /// UPDATE entity
  Future<void> updateEntity(Entity entity, File? imageFile) async {
    if (entity.id == null) {
      throw Exception('Cannot update: missing entity ID');
    }
    
    var request = http.MultipartRequest('PUT', Uri.parse(baseUrl));
    request.fields['id'] = entity.id!.toString();
    request.fields['title'] = entity.title;
    request.fields['lat'] = entity.lat.toString();
    request.fields['lon'] = entity.lon.toString();
    
    if (imageFile != null) {
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
    } catch (_) {
      // Fallback
    }
    
    var fallbackRequest = http.MultipartRequest('POST', Uri.parse(baseUrl));
    fallbackRequest.fields['_method'] = 'PUT';
    fallbackRequest.fields['id'] = entity.id!.toString();
    fallbackRequest.fields['title'] = entity.title;
    fallbackRequest.fields['lat'] = entity.lat.toString();
    fallbackRequest.fields['lon'] = entity.lon.toString();
    
    if (imageFile != null) {
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      fallbackRequest.files.add(multipartFile);
    }
    
    final streamedFallback = await fallbackRequest.send();
    final fallbackResponse = await http.Response.fromStream(streamedFallback);
    
    if (!(fallbackResponse.statusCode >= 200 && fallbackResponse.statusCode < 300)) {
      throw Exception('Failed to update entity: ${fallbackResponse.statusCode}');
    }
  }

  Future<void> deleteEntity(int? id) async {
    if (id == null) throw Exception('Cannot delete: id is null');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl?id=$id'), 
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return;
    } catch (_) {
      // If DELETE method fails, try the POST fallback
    }

    // Fallback: POST with _method=DELETE (PHP Specific)
    final response2 = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'_method': 'DELETE', 'id': id.toString()},
    );

    if (!(response2.statusCode >= 200 && response2.statusCode < 300)) {
      throw Exception('Failed to delete entity: ${response2.statusCode}');
    }
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';
    final raw = imagePath.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return imageBaseUrl + raw.replaceAll('\\', '/');
  }
}