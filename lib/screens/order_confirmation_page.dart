import 'dart:async';
import 'package:flutter/material.dart';
import 'package:g_g/screens/customer_homescreen.dart';
import 'package:g_g/screens/order_history_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final String deliveryTime;
  final String restaurantName;

  OrderConfirmationScreen({
    required this.orderId,
    required this.totalAmount,
    required this.deliveryTime,
    required this.restaurantName,
  });

  @override
  _OrderConfirmationScreenState createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRedirectionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRedirectionTimer() {
    _timer = Timer(Duration(minutes: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        );
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSuccessIcon(),
              SizedBox(height: 30),
              _buildOrderSuccessText(),
              SizedBox(height: 20),
              _buildOrderDetails(),
              SizedBox(height: 30),
              _buildOrderNumber(),
              SizedBox(height: 20),
              _buildDeliveryTime(),
              SizedBox(height: 30),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 100,
      ),
    );
  }

  Widget _buildOrderSuccessText() {
    return Center(
      child: Text(
        'Order Confirmed!',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Center(
      child: Column(
        children: [
          Text(
            'Thank you for your order from ${widget.restaurantName}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Amount Paid: ₹${widget.totalAmount}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNumber() {
    return Center(
      child: Column(
        children: [
          Text(
            'Order Number',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.orderId,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTime() {
    return Center(
      child: Column(
        children: [
          Text(
            'Estimated Delivery Time',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.deliveryTime,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'View Order History',
            style: TextStyle(fontSize: 18),
          ),
        ),
        SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
            );
          },
          child: Text(
            'Back to Home',
            style: TextStyle(fontSize: 18, color: Colors.teal),
          ),
        ),
      ],
    );
  }
}
