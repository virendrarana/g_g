import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String restaurantId;
  final String name;
  final String address;
  final String geoPointString;
  final String imageUrl;
  final String cuisine;
  final double rating;
  final String? videoUrl;

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.geoPointString,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    this.videoUrl,
  });

  // Convert a GeoPoint to a string
  static String geoPointToString(GeoPoint geoPoint) {
    return '${geoPoint.latitude},${geoPoint.longitude}';
  }

  // Convert a string back to a GeoPoint
  static GeoPoint stringToGeoPoint(String geoPointString) {
    final parts = geoPointString.split(',');
    final latitude = double.parse(parts[0]);
    final longitude = double.parse(parts[1]);
    return GeoPoint(latitude, longitude);
  }

  // Factory method to create a Restaurant instance from a Firestore document
  factory Restaurant.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      restaurantId: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      geoPointString: data['geoPointString'] ?? '0.0,0.0',
      imageUrl: data['imageUrl'] ?? '',
      cuisine: data['cuisine'] ?? '',
      rating: data['rating']?.toDouble() ?? 0.0,
      videoUrl: data['videoUrl'],
    );
  }

  // Convert the Restaurant instance to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'geoPointString': geoPointString,
      'imageUrl': imageUrl,
      'cuisine': cuisine,
      'rating': rating,
      'videoUrl': videoUrl,
    };
  }
}
