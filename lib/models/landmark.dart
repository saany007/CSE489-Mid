class Landmark {
  final int? id;
  final String title;
  final double lat;
  final double lon;
  final String? image;

  Landmark({
    this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
  });

  // Factory constructor to create a Landmark from JSON
  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      title: json['title'] ?? '',
      lat: _parseDouble(json['lat']),
      lon: _parseDouble(json['lon']),
      image: json['image'],
    );
  }

  // Helper method to parse double values from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Convert Landmark to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  // Convert to Map for local database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
    };
  }

  // Create Landmark from database map
  factory Landmark.fromMap(Map<String, dynamic> map) {
    return Landmark(
      id: map['id'],
      title: map['title'],
      lat: map['lat'],
      lon: map['lon'],
      image: map['image'],
    );
  }

  // Get full image URL
  String? get fullImageUrl {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return 'https://labs.anontech.info/cse489/t3/$image';
  }

  // Create a copy with updated fields
  Landmark copyWith({
    int? id,
    String? title,
    double? lat,
    double? lon,
    String? image,
  }) {
    return Landmark(
      id: id ?? this.id,
      title: title ?? this.title,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'Landmark{id: $id, title: $title, lat: $lat, lon: $lon, image: $image}';
  }
}