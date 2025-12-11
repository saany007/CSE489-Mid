// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle; // Required for loading assets
import 'package:location/location.dart' as loc;

// CORRECT IMPORTS (Matches your pubspec.yaml name: geo_entities_app)
import 'package:geo_entities_app/models/entity.dart';
import 'package:geo_entities_app/services/api_service.dart';
import 'package:geo_entities_app/services/location_service.dart';
import 'package:geo_entities_app/screens/entity_form_screen.dart';

class MapScreen extends StatefulWidget {
  final bool showAppBar;
  
  const MapScreen({super.key, this.showAppBar = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  List<Entity> _entities = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;

  GoogleMapController? _mapController;
  
  // NEW: Variable to store the loaded map style
  String? _mapStyle; 

  // Center on Bangladesh
  static const LatLng _bangladeshCenter = LatLng(23.6850, 90.3563);
  static const double _defaultZoom = 6.95;

  bool _locationPermissionGranted = false;
  loc.LocationData? _currentLocationData;

  @override
  void initState() {
    super.initState();
    // 1. Load the Night Mode style from assets
    _loadMapStyle(); 
    // 2. Fetch data
    _fetchEntitiesAndCheckLocation();
  }

  // === NEW FUNCTION: Loads the style from assets/map_style.json ===
  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.json');
      // If map is already visible, update it immediately
      if (_mapController != null) {
        _mapController!.setMapStyle(_mapStyle);
      }
    } catch (e) {
      print("Error loading map style: $e");
    }
  }
  // ================================================================

  Future<void> _fetchEntitiesAndCheckLocation() async {
    try {
      final entities = await _apiService.getEntities();
      final locationData = await LocationService.getCurrentLocation();
      setState(() {
        _entities = entities;
        _isLoading = false;
        _currentLocationData = locationData;
        _locationPermissionGranted = locationData != null;
      });
      _buildMarkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map refreshed!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationPermissionGranted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (final e in _entities) {
      if (e.lat != 0.0 && e.lon != 0.0) {
        markers.add(Marker(
          markerId: MarkerId(e.id?.toString() ?? e.title),
          position: LatLng(e.lat, e.lon),
          infoWindow: InfoWindow(
            title: e.title,
            snippet: 'Tap for details',
          ),
          onTap: () => _showEntityBottomSheet(e),
        ));
      }
    }
    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Apply the style if it has finished loading
    if (_mapStyle != null) {
      _mapController!.setMapStyle(_mapStyle);
    }
  }

  void _centerMapOnBangladesh() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        const CameraPosition(target: _bangladeshCenter, zoom: _defaultZoom),
      ));
    }
  }

  // === EXACT ORIGINAL UI: Draggable Bottom Sheet Logic ===
  void _showEntityBottomSheet(Entity entity) {
    final imageUrl = _apiService.getFullImageUrl(entity.image);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false, // Ensures it behaves like a sheet, not full screen
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Title
                  Text(
                    entity.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location info
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${entity.lat.toStringAsFixed(4)}, ${entity.lon.toStringAsFixed(4)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Image preview
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('No image available'),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons (Edit / Delete)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context); // Close sheet
                            // Navigate to Edit Screen
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EntityFormScreen(entity: entity),
                              ),
                            );
                            if (result == true) {
                              _fetchEntitiesAndCheckLocation();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context); // Close sheet
                            // Confirmation Dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Landmark'),
                                content: Text('Delete "${entity.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true && entity.id != null) {
                              try {
                                await _apiService.deleteEntity(entity.id);
                                _fetchEntitiesAndCheckLocation();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Deleted successfully')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete failed: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // === EXACT ORIGINAL UI: Stack with FABs ===
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _bangladeshCenter,
                  zoom: _defaultZoom,
                ),
                markers: _markers,
                onMapCreated: _onMapCreated,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
              ),
              
              // Custom location buttons
              Positioned(
                left: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'center_bd',
                      onPressed: _centerMapOnBangladesh,
                      tooltip: 'Center on Bangladesh',
                      child: const Icon(Icons.public),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'center_me',
                      onPressed: () {
                        if (_currentLocationData != null && _mapController != null) {
                          final lat = _currentLocationData!.latitude!;
                          final lon = _currentLocationData!.longitude!;
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(LatLng(lat, lon), 14.0),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Location not available')),
                          );
                        }
                      },
                      tooltip: 'My location',
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
              
              // Refresh button 
              Positioned(
                right: 16,
                top: 16,  
                child: SafeArea( 
                  child: FloatingActionButton(
                    heroTag: 'refresh_map',
                    onPressed: _fetchEntitiesAndCheckLocation,
                    tooltip: 'Refresh',
                    child: const Icon(Icons.refresh),
                  ),
                ),
              ),
            ],
          );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: body,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}