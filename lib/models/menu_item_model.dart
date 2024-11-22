import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  String? id; // Firestore document ID
  final String name;
  final String description;
  final double price; // Base price
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final String type;
  final bool supportsPortionSizes;
  final Map<String, double>? portionSizes; // Dynamic portion sizes

  MenuItem({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.type,
    this.supportsPortionSizes = false,
    this.portionSizes, // Optional map for portion sizes
  });

  // Convert MenuItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'type': type,
      'supportsPortionSizes': supportsPortionSizes,
      'portionSizes': portionSizes, // Store portion sizes as a map
    };
  }

  // Create MenuItem from Firestore DocumentSnapshot
  factory MenuItem.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      isAvailable: data['isAvailable'] ?? true,
      type: data['type'] ?? 'Unknown',
      supportsPortionSizes: data['supportsPortionSizes'] ?? false,
      portionSizes: (data['portionSizes'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())),
    );
  }
}
