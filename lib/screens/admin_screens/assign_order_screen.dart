import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignOrderScreen extends StatefulWidget {
  @override
  _AssignOrderScreenState createState() => _AssignOrderScreenState();
}

class _AssignOrderScreenState extends State<AssignOrderScreen> {
  String? selectedOrderId;
  String? selectedPartnerId;
  List<DocumentSnapshot> deliveryPartners = [];
  List<DocumentSnapshot> pendingOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
    _fetchDeliveryPartners();
  }

  // Fetch only pending orders that haven't been assigned
  void _fetchPendingOrders() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'Pending') // Fetch only pending orders
        .where('assignedTo', isNull: true) // Ensure the order is not yet assigned
        .get();

    setState(() {
      pendingOrders = snapshot.docs;
    });
  }

  // Fetch users who are delivery partners
  void _fetchDeliveryPartners() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'DeliveryPartner') // Fetch delivery partners only
        .get();

    setState(() {
      deliveryPartners = snapshot.docs;
    });
  }

  // Assign order to the selected delivery partner
  void _assignOrder() async {
    if (selectedOrderId != null && selectedPartnerId != null) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(selectedOrderId)
          .update({
        'assignedTo': selectedPartnerId, // Assign delivery partner's ID to the order
        'status': 'Assigned', // Optionally, change the order status to "Assigned"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order assigned successfully!')),
      );

      setState(() {
        selectedOrderId = null;
        selectedPartnerId = null;
        _fetchPendingOrders(); // Refresh the list of pending orders after assignment
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an order and a delivery partner.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Orders'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              hint: Text('Select Pending Order'),
              value: selectedOrderId,
              items: pendingOrders.map((order) {
                return DropdownMenuItem<String>(
                  value: order.id,
                  child: Text('Order #${order.id} - Total: ₹${order['totalAmount']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOrderId = value;
                });
              },
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              hint: Text('Select Delivery Partner'),
              value: selectedPartnerId,
              items: deliveryPartners.map((partner) {
                return DropdownMenuItem<String>(
                  value: partner.id,
                  child: Text(partner['fullName']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPartnerId = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _assignOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Assign Order',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
