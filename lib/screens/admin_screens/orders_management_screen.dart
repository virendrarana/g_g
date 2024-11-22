import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_g/screens/admin_screens/Order_detail_screen.dart';

class OrderManagementScreen extends StatefulWidget {
  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  final List<String> _orderStatuses = [
    'All',
    'Pending',
    'Processing',
    'Out For Delivery',
    'Assigned',
    'Delivered',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Management'),
        backgroundColor: Colors.teal,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                // Filter Dropdown
                DropdownButton<String>(
                  value: _filterStatus,
                  items: _orderStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                  underline: Container(),
                  dropdownColor: Colors.teal,
                  style: TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildOrderList(),
    );
  }

  Widget _buildOrderList() {
    Query query =
    FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true);

    if (_searchQuery.isNotEmpty) {
      query = query.where('orderId', isEqualTo: _searchQuery);
    }

    if (_filterStatus != 'All') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading orders.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No orders found.'));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(order['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text('Error fetching user information.')),
                    ),
                  );
                }

                final userDoc = userSnapshot.data!;
                final customerName = userDoc.exists ? userDoc['fullName'] : 'Unknown Customer';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order ID: ${order['orderId']}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order['status'],
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Total Amount
                        Text('Total: ₹${order['totalAmount']}'),
                        SizedBox(height: 8),
                        // Customer ID and Full Name
                        Text('Customer ID: ${order['userId']}'),
                        Text('Customer Name: $customerName'),
                        SizedBox(height: 8),
                        // Updated At
                        Row(
                          children: [
                            Text('Updated At: '),
                            Text(
                              order['updatedAt'] != null
                                  ? order['updatedAt'].toDate().toString()
                                  : 'N/A',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Actions: View Details and Update Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderDetailScreen(orderId: order['orderId']),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('View Details'),
                            ),
                            DropdownButton<String>(
                              value: order['status'],
                              icon: Icon(Icons.arrow_downward),
                              elevation: 16,
                              style: TextStyle(color: Colors.teal),
                              underline: Container(
                                height: 2,
                                color: Colors.tealAccent,
                              ),
                              onChanged: (String? newValue) async {
                                if (newValue != null && newValue != order['status']) {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirm Status Change'),
                                      content: Text('Change status to "$newValue"?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () => Navigator.of(context).pop(false),
                                        ),
                                        TextButton(
                                          child: Text('Confirm'),
                                          onPressed: () => Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                      false;

                                  if (confirm) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order.id)
                                          .update({
                                        'status': newValue,
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Order status updated to "$newValue".')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to update status: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              items: _orderStatuses
                                  .where((status) => status != 'All')
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Assigned':
        return Colors.cyan;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
