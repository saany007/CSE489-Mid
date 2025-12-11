import 'dart:io';
import 'package:flutter/material.dart';
import '../models/landmark.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class LandmarkProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Landmark> _landmarks = [];
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;

  List<Landmark> get landmarks => _landmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;

  // Fetch all landmarks
  Future<void> fetchLandmarks({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to fetch from API
      _landmarks = await _apiService.fetchLandmarks();
      _isOfflineMode = false;
      
      // Cache the data
      await _databaseHelper.cacheLandmarks(_landmarks);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching landmarks: $e');
      
      // Try to load from cache
      try {
        _landmarks = await _databaseHelper.getCachedLandmarks();
        _isOfflineMode = true;
        _error = 'Using offline data. Unable to connect to server.';
      } catch (cacheError) {
        _error = 'Failed to load landmarks: $e';
        _landmarks = [];
        _isOfflineMode = false;
      }
      
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new landmark
  Future<bool> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      await _apiService.createLandmark(
        title: title,
        lat: lat,
        lon: lon,
        imageFile: imageFile,
      );
      
      // Refresh the list
      await fetchLandmarks();
      return true;
    } catch (e) {
      _error = 'Failed to create landmark: $e';
      notifyListeners();
      return false;
    }
  }

  // Update an existing landmark
  Future<bool> updateLandmark({
    required int id,
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      await _apiService.updateLandmark(
        id: id,
        title: title,
        lat: lat,
        lon: lon,
        imageFile: imageFile,
      );
      
      // Refresh the list
      await fetchLandmarks();
      return true;
    } catch (e) {
      _error = 'Failed to update landmark: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a landmark
  Future<bool> deleteLandmark(int id) async {
    try {
      await _apiService.deleteLandmark(id);
      
      // Refresh the list
      await fetchLandmarks();
      return true;
    } catch (e) {
      _error = 'Failed to delete landmark: $e';
      notifyListeners();
      return false;
    }
  }

  // Get a single landmark by ID
  Landmark? getLandmarkById(int id) {
    try {
      return _landmarks.firstWhere((landmark) => landmark.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear cache
  Future<void> clearCache() async {
    await _databaseHelper.clearCache();
  }
}