import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_g/models/order_model.dart';

class OrderService {
  final CollectionReference _orderCollection =
  FirebaseFirestore.instance.collection('orders');

  // Get all orders from Firestore
  Future<List<OrderG>> getAllOrders() async {
    try {
      QuerySnapshot querySnapshot = await _orderCollection.get();
      return querySnapshot.docs
          .map((doc) => OrderG.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Failed to get orders: $e");
      return [];
    }
  }

  // Update an order in Firestore
  Future<void> updateOrder(OrderG order) async {
    try {
      await _orderCollection.doc(order.orderId).update(order.toMap());
      print("Order updated successfully!");
    } catch (e) {
      print("Failed to update order: $e");
    }
  }
}
