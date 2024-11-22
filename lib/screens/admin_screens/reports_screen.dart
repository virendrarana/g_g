import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _totalSales = 0.0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance.collection('orders').get();
      double totalSales = 0.0;
      int totalOrders = ordersSnapshot.docs.length;

      for (var order in ordersSnapshot.docs) {
        totalSales += order['totalAmount'];
      }

      setState(() {
        _totalSales = totalSales;
        _totalOrders = totalOrders;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Sales: ₹$_totalSales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Total Orders: $_totalOrders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text('Additional analytics can be displayed here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
