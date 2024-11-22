import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String itemId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'].toDouble(),
    );
  }
}

class OrderG {
  final String orderId;
  final String userId;
  final String restaurantId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final Timestamp orderDate;
  final String? address;

  OrderG({
    required this.orderId,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'restaurantId': restaurantId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate,
      'address': address,
    };
  }

  factory OrderG.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderG(
      orderId: doc.id,
      userId: data['userId'],
      restaurantId: data['restaurantId'],
      items: List<OrderItem>.from(
        data['items'].map((item) => OrderItem.fromMap(item)),
      ),
      totalAmount: data['totalAmount'].toDouble(),
      status: data['status'],
      orderDate: data['orderDate'],
      address: data['address'],
    );
  }
}
