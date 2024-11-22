class CartItem {
  final String id;
  final String name;
  late final double price;
  int quantity;
  final String imageUrl;
  final String? portionSize; // New field to track portion size
  final double? halfPortionPrice; // For portion-specific price
  final double? fullPortionPrice; // For portion-specific price

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.portionSize, // Optional portion size
    this.halfPortionPrice, // Half portion price, if applicable
    this.fullPortionPrice, // Full portion price, if applicable
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'portionSize': portionSize, // Store portion size
      'halfPortionPrice': halfPortionPrice, // Store half portion price
      'fullPortionPrice': fullPortionPrice, // Store full portion price
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
      imageUrl: map['imageUrl'],
      portionSize: map['portionSize'], // Parse portion size
      halfPortionPrice: map['halfPortionPrice'], // Parse half portion price
      fullPortionPrice: map['fullPortionPrice'], // Parse full portion price
    );
  }
}
