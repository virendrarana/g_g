import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  OrderDetailScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Logging error to understand what's happening
            print("Error fetching order details: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            // If the document doesn't exist or there's no data
            return Center(child: Text('Order not found.'));
          }

          // Getting order data safely with typecasting and null checks
          var orderData = snapshot.data!.data() as Map<String, dynamic>?;

          if (orderData == null) {
            return Center(child: Text('No order data available.'));
          }

          // Safely access fields to avoid null-related errors
          String orderId = orderData['orderId'] ?? 'N/A';
          String customerName = orderData['customerName'] ?? 'N/A';
          String customerId = orderData['userId'] ?? 'N/A';
          String status = orderData['status'] ?? 'N/A';
          double totalAmount = orderData['totalAmount'] != null
              ? orderData['totalAmount'].toDouble()
              : 0.0;

          // Delivery address handling with null safety
          var deliveryAddress = orderData['deliveryAddress'] ?? {};
          String street = deliveryAddress['street'] ?? 'N/A';
          String city = deliveryAddress['city'] ?? 'N/A';
          String state = deliveryAddress['state'] ?? 'N/A';
          String zip = deliveryAddress['zip'] ?? 'N/A';
          String country = deliveryAddress['country'] ?? 'N/A';

          // Timestamps handling
          Timestamp? createdAtTimestamp = orderData['createdAt'];
          Timestamp? updatedAtTimestamp = orderData['updatedAt'];

          String createdAt = createdAtTimestamp != null
              ? createdAtTimestamp.toDate().toString()
              : 'N/A';
          String updatedAt = updatedAtTimestamp != null
              ? updatedAtTimestamp.toDate().toString()
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: $orderId',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Customer ID: $customerId'),
                  SizedBox(height: 10),
                  Text('Customer Name: $customerName'),
                  SizedBox(height: 10),
                  Text('Status: $status'),
                  SizedBox(height: 10),
                  Text('Total Amount: ₹$totalAmount'),
                  SizedBox(height: 20),
                  Text(
                    'Delivery Address:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(street),
                  Text('$city, $state - $zip'),
                  Text(country),
                  SizedBox(height: 20),
                  Text(
                    'Items:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (orderData['items'] != null)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: (orderData['items'] as List).length,
                      itemBuilder: (context, index) {
                        var item = orderData['items'][index];
                        return ListTile(
                          title: Text(item['name'] ?? 'N/A'),
                          subtitle: Text('Quantity: ${item['quantity'] ?? 'N/A'}'),
                          trailing: Text('₹${item['price'] ?? 'N/A'}'),
                        );
                      },
                    )
                  else
                    Text('No items found.'),
                  SizedBox(height: 20),
                  Text(
                    'Timestamps:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('Created At: $createdAt'),
                  Text('Last Updated: $updatedAt'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
