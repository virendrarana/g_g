import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveOrderToFirestore({
  required String orderId,
  required String totalAmount,
  required String deliveryTime,
  required String restaurantName,
  required List<Map<String, dynamic>> items,
}) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;
  if (user == null) {
    throw Exception('No user is currently signed in.');
  }

  final orderData = {
    'orderId': orderId,
    'userId': user.uid,
    'userName': user.displayName ?? 'Anonymous',
    'userEmail': user.email ?? '',
    'userPhone': user.phoneNumber ?? '',
    'totalAmount': totalAmount,
    'deliveryTime': deliveryTime,
    'restaurantName': restaurantName,
    'items': items,
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending', // Initial status
  };

  await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
}
