import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/entity.dart';
import 'package:geo_entities_app/services/api_service.dart';
import 'package:geo_entities_app/screens/entity_form_screen.dart';

class EntityListScreen extends StatefulWidget {
  final bool showAppBar;
  
  const EntityListScreen({super.key, this.showAppBar = true});

  @override
  State<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends State<EntityListScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Entity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEntities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchEntities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final entities = await _apiService.getEntities();
      if (mounted) {
        setState(() {
          _entities = entities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteEntity(int? id, int index) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid entity id')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Landmark'),
        content: Text('Are you sure you want to delete "${_entities[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteEntity(id);
      if (!mounted) return;
      
      setState(() {
        _entities.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _scrollToEnd() async {
    if (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final distance = (maxScroll - current).abs();

    if (distance <= 5) return;

    final int durationMs = ((distance / 1000) * 900).clamp(300, 1400).toInt();

    await _scrollController.animateTo(
      maxScroll,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _entities.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No landmarks found'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchEntities,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchEntities,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _entities.length,
                  itemBuilder: (context, index) {
                    final entity = _entities[index];
                    return _buildEntityCard(entity, index);
                  },
                ),
              );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entity List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            tooltip: 'Scroll to end',
            onPressed: _scrollToEnd,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchEntities,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildEntityCard(Entity entity, int index) {
    final imageUrl = _apiService.getFullImageUrl(entity.image);
    
    return Dismissible(
      key: Key('entity_${entity.id}_$index'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Edit
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntityFormScreen(entity: entity),
            ),
          );
          if (result == true) {
            _fetchEntities();
          }
          return false; // Don't dismiss
        } else {
          // Swipe left - Delete
          return await showDialog<bool>(
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
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteEntity(entity.id, index);
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showEntityDetails(entity),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                
                const SizedBox(width: 16),
                
                // Title and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entity.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${entity.lat.toStringAsFixed(4)}, ${entity.lon.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EntityFormScreen(entity: entity),
                          ),
                        );
                        if (result == true) {
                          _fetchEntities();
                        }
                      },
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteEntity(entity.id, index),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );
  }

  void _showEntityDetails(Entity entity) {
    final imageUrl = _apiService.getFullImageUrl(entity.image);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(entity.title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (imageUrl.isNotEmpty)
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('Failed to load image')),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No image available'),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Latitude: ${entity.lat}'),
                  Text('Longitude: ${entity.lon}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}