class Entity {
  final int? id;
  final String title;
  final double lat;
  final double lon;
  final String? image;

  Entity({
    this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    String latStr = json['lat']?.toString() ?? '0';
    String lonStr = json['lon']?.toString() ?? '0';

    int? parsedId;
    if (json['id'] != null && json['id'].toString().isNotEmpty) {
      parsedId = int.tryParse(json['id'].toString());
    }

    return Entity(
      id: parsedId,
      title: json['title'] as String? ?? '',
      lat: double.tryParse(latStr) ?? 0.0,
      lon: double.tryParse(lonStr) ?? 0.0,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  bool isValid() {
    return title.isNotEmpty && lat != 0.0 && lon != 0.0;
  }
}
