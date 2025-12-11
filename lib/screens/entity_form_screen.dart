// lib/screens/entity_form_screen.dart
import 'dart:io';
import 'dart:async'; // Needed for Timeout
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geo_entities_app/models/entity.dart';
import 'package:geo_entities_app/services/api_service.dart';
import 'package:geo_entities_app/services/location_service.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'select_location_screen.dart';

class EntityFormScreen extends StatefulWidget {
  final Entity? entity;

  const EntityFormScreen({super.key, this.entity});

  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entity?.title ?? '');
    _latController = TextEditingController(text: widget.entity?.lat.toString() ?? '');
    _lonController = TextEditingController(text: widget.entity?.lon.toString() ?? '');
    
    // Auto-detect GPS for new landmarks
    if (widget.entity == null) {
      _getCurrentLocation();
    }
  }

  // === FIXED FUNCTION: Includes 4-second Timeout ===
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to get location, but give up after 4 seconds if Emulator is stuck
      final locationData = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 4)); 

      if (locationData != null && mounted) {
        setState(() {
          _latController.text = locationData.latitude?.toString() ?? '';
          _lonController.text = locationData.longitude?.toString() ?? '';
        });
      }
    } on TimeoutException catch (_) {
      // If it takes too long, just stop loading
      debugPrint("Location timed out");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS slow. Please enter location manually.')),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      // ALWAYS stop loading, no matter what
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // ===============================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<File?> _resizeImage(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return originalFile;

      // Resize to 800x600 as per requirements
      final resized = img.copyResize(image, width: 800, height: 600);
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(
        tempDir.path,
        'resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final resizedFile = File(tempPath);
      await resizedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));
      return resizedFile;
    } catch (e) {
      debugPrint('Image resize error: $e');
      return originalFile;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final latVal = double.tryParse(_latController.text.trim());
    final lonVal = double.tryParse(_lonController.text.trim());
    
    if (latVal == null || lonVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coordinates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      File? submitImage = _imageFile;
      if (submitImage != null) {
        submitImage = await _resizeImage(submitImage);
      }

      final entity = Entity(
        id: widget.entity?.id,
        title: _titleController.text.trim(),
        lat: latVal,
        lon: lonVal,
      );

      if (widget.entity == null) {
        // === CREATE NEW ENTITY ===
        await _apiService.createEntity(entity, submitImage);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Landmark created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // === FIX STARTS HERE ===
          // Check if we can "go back". If not (we are on the Tab), just reset the form.
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          } else {
            // We are on the Tab. Clear the form for the next entry.
            _titleController.clear();
            setState(() {
              _imageFile = null;
            });
            // Optional: You could switch to the "Records" tab here if you wanted
          }
          // === FIX ENDS HERE ===
        }
      } else {
        // === UPDATE EXISTING ENTITY ===
        await _apiService.updateEntity(entity, submitImage);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Landmark updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // When editing, we pushed a new screen, so popping is always safe here.
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _chooseLocationOnMap() async {
    LatLng? initial;
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    if (lat != null && lon != null) {
      initial = LatLng(lat, lon);
    }

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationScreen(initialPosition: initial),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lonController.text = result.longitude.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entity != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Landmark' : 'New Landmark'),
      ),
      body: _isLoading && widget.entity == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter landmark name',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Title is required'
                              : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Latitude field
                    TextFormField(
                      controller: _latController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        hintText: '23.6850',
                        prefixIcon: const Icon(Icons.my_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Latitude is required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Longitude field
                    TextFormField(
                      controller: _lonController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        hintText: '90.3563',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Longitude is required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Choose location button
                    OutlinedButton.icon(
                      onPressed: _chooseLocationOnMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Choose location on map'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Get current location button
                    OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.gps_fixed),
                      label: const Text('Use current location'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Image section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Landmark Image',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Image preview
                            if (_imageFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (widget.entity?.image != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _apiService.getFullImageUrl(widget.entity!.image),
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image, size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No image selected'),
                                    ],
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose Image'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading && widget.entity != null ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading && widget.entity != null
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'Update Landmark' : 'Create Landmark',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
}