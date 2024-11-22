import 'package:flutter/foundation.dart';
import 'package:g_g/models/cart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

class Cart with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Constructor to load cart data on initialization
  Cart() {
    _loadCartFromPreferences();
  }

  // Load cart items from SharedPreferences
  void _loadCartFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString('cart_items');
    if (cartData != null) {
      List<dynamic> decodedItems = json.decode(cartData);
      _items = decodedItems.map((item) => CartItem.fromMap(item)).toList();
      notifyListeners();
    }
  }

  // Save cart items to SharedPreferences
  void _saveCartToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cartItemsMap =
    _items.map((item) => item.toMap()).toList();
    String encodedCart = json.encode(cartItemsMap);
    await prefs.setString('cart_items', encodedCart);
  }

  // Add an item to the cart
  void addItem(CartItem item, {bool isPremiumUser = false}) {
    // Adjust price for premium users
    double adjustedPrice = isPremiumUser ? item.price * 0.85 : item.price;

    var existingItem = _items.firstWhere(
          (element) => element.id == item.id,
      orElse: () => CartItem(
        id: '',
        name: '',
        price: 0.0,
        quantity: 0,
        imageUrl: '',
      ),
    );

    if (existingItem.id.isNotEmpty) {
      existingItem.quantity += item.quantity;
      existingItem.price = adjustedPrice; // Update the price if already in the cart
    } else {
      _items.add(CartItem(
        id: item.id,
        name: item.name,
        price: adjustedPrice,
        quantity: item.quantity,
        imageUrl: item.imageUrl,
        portionSize: item.portionSize,
      ));
    }

    _saveCartToPreferences(); // Save the cart to SharedPreferences
    notifyListeners();
  }

  // Remove an item from the cart
  void removeItem(String id) {
    var existingItem = _items.firstWhere(
          (element) => element.id == id,
      orElse: () => CartItem(
        id: '',
        name: '',
        price: 0.0,
        quantity: 0,
        imageUrl: '',
      ),
    );

    if (existingItem.id.isNotEmpty) {
      if (existingItem.quantity > 1) {
        existingItem.quantity -= 1;
      } else {
        _items.remove(existingItem);
      }
      _saveCartToPreferences(); // Save the cart to SharedPreferences
      notifyListeners();
    }
  }

  // Get the quantity of a specific item
  int getQuantity(String id) {
    var existingItem = _items.firstWhere(
          (element) => element.id == id,
      orElse: () => CartItem(
        id: '',
        name: '',
        price: 0.0,
        quantity: 0,
        imageUrl: '',
      ),
    );
    return existingItem.id.isNotEmpty ? existingItem.quantity : 0;
  }

  // Get the total amount for the items in the cart
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Get the total count of items in the cart
  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Clear all items from the cart
  void clearCart() {
    _items.clear();
    _saveCartToPreferences(); // Save the cart to SharedPreferences
    notifyListeners();
  }

  // Clear all items from memory without saving
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
