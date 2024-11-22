import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: user != null ? _buildOrderHistoryList() : Center(child: Text('No user logged in')),
    );
  }

  Widget _buildOrderHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No orders found.'));
        }

        var orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var orderData = orders[index].data() as Map<String, dynamic>;

            String orderId = orders[index].id;
            DateTime orderDate = (orderData['orderDate'] as Timestamp).toDate();
            double totalAmount = orderData['totalAmount'].toDouble();
            List<dynamic> items = orderData['items'];
            String restaurantName = orderData['restaurantName'] ?? 'Unknown Restaurant';

            return _buildOrderTile(orderId, orderDate, totalAmount, items, restaurantName);
          },
        );
      },
    );
  }

  Widget _buildOrderTile(String orderId, DateTime orderDate, double totalAmount, List<dynamic> items, String restaurantName) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 5,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          'Order #$orderId',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Date: ${orderDate.toLocal()}',
              style: TextStyle(color: Colors.black54),
            ),
            Text(
              'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ],
        ),
        children: [
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['name']} x${item['quantity']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
