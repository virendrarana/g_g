import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
//import 'restaurant_model.dart';  // Make sure this path matches your project structure

class RestaurantService {
  final CollectionReference _restaurantCollection =
  FirebaseFirestore.instance.collection('restaurants');

  // Add a new restaurant to Firestore
  Future<void> addRestaurant(Restaurant restaurant) async {
    try {
      await _restaurantCollection.doc(restaurant.restaurantId).set(restaurant.toMap());
      print("Restaurant added successfully!");
    } catch (e) {
      print("Failed to add restaurant: $e");
    }
  }

  // Get a restaurant by ID from Firestore
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      DocumentSnapshot doc = await _restaurantCollection.doc(id).get();
      if (doc.exists) {
        return Restaurant.fromDocument(doc);
      } else {
        print("Restaurant not found");
        return null;
      }
    } catch (e) {
      print("Failed to get restaurant: $e");
      return null;
    }
  }

  // Get all restaurants from Firestore
  Future<List<Restaurant>> getAllRestaurants() async {
    final snapshot = await FirebaseFirestore.instance.collection('restaurants').get();
    return snapshot.docs.map((doc) => Restaurant.fromDocument(doc)).toList();
  }


  // Update a restaurant in Firestore
  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      await _restaurantCollection.doc(restaurant.restaurantId).update(restaurant.toMap());
      print("Restaurant updated successfully!");
    } catch (e) {
      print("Failed to update restaurant: $e");
    }
  }

  // Delete a restaurant from Firestore
  Future<void> deleteRestaurant(String id) async {
    try {
      await _restaurantCollection.doc(id).delete();
      print("Restaurant deleted successfully!");
    } catch (e) {
      print("Failed to delete restaurant: $e");
    }
  }
}
