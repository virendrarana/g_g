// services/menu_item_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuItemService {
  // Get a reference to the menuItems sub-collection under a specific restaurant
  CollectionReference getMenuItemsCollection(String restaurantId) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menuItems');
  }

  // Add a new menu item to a specific restaurant's menuItems collection
  Future<void> addMenuItem(String restaurantId, MenuItem menuItem) async {
    try {
      await getMenuItemsCollection(restaurantId).add(menuItem.toMap());
      print("Menu item added successfully!");
    } catch (e) {
      print("Failed to add menu item: $e");
      throw e; // Rethrow to handle in UI if needed
    }
  }

  // Get all menu items for a specific restaurant as a Future
  Future<List<MenuItem>> getMenuItemsByRestaurant(String restaurantId) async {
    try {
      QuerySnapshot querySnapshot =
      await getMenuItemsCollection(restaurantId).get();
      return querySnapshot.docs
          .map((doc) => MenuItem.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Failed to get menu items: $e");
      return [];
    }
  }

  // Get all menu items as a stream for real-time updates
  Stream<List<MenuItem>> streamMenuItemsByRestaurant(String restaurantId) {
    return getMenuItemsCollection(restaurantId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MenuItem.fromDocument(doc)).toList());
  }



  // Update an existing menu item in a specific restaurant's menuItems collection
  Future<void> updateMenuItem(String restaurantId, MenuItem menuItem) async {
    try {
      await getMenuItemsCollection(restaurantId)
          .doc(menuItem.id)
          .update(menuItem.toMap());
      print("Menu item updated successfully!");
    } catch (e) {
      print("Failed to update menu item: $e");
      throw e;
    }
  }

  // Delete a menu item from a specific restaurant's menuItems collection
  Future<void> deleteMenuItem(String restaurantId, String menuItemId) async {
    try {
      await getMenuItemsCollection(restaurantId).doc(menuItemId).delete();
      print("Menu item deleted successfully!");
    } catch (e) {
      print("Failed to delete menu item: $e");
      throw e;
    }
  }
}
