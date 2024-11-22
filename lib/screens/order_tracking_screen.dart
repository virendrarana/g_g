import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  OrderTrackingScreen({required this.orderId, required String userId});

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String _status = '';
  String _assignedTo = '';
  double _totalAmount = 0.0;
  String _address = '';
  String _paymentMethod = '';
  List<dynamic> _items = [];
  Timestamp? _orderDate;
  String _customerName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _listenToOrderStatus();
  }

  // Fetch initial order details
  void _fetchOrderDetails() async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderSnapshot.exists) {
        setState(() {
          _status = orderSnapshot['status'] ?? 'Unknown';
          _assignedTo = orderSnapshot['assignedTo'] ?? 'Not Assigned';
          _totalAmount = (orderSnapshot['totalAmount'] ?? 0.0).toDouble();
          _address = orderSnapshot['address'] ?? 'No Address Provided';
          _paymentMethod = orderSnapshot['paymentMethod'] ?? 'Not Specified';
          _items = orderSnapshot['items'] ?? [];
          _orderDate = orderSnapshot['orderDate'];
          _customerName = orderSnapshot['customerName'] ?? 'Not Available';
          _userId = orderSnapshot['userId'] ?? 'Not Available';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch order details: $e')),
      );
    }
  }

  // Listen to real-time updates on order status
  void _listenToOrderStatus() {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _status = snapshot['status'] ?? 'Unknown';
          _assignedTo = snapshot['assignedTo'] ?? 'Not Assigned';
        });
      }
    });
  }

  // Map order status to a progress step
  List<String> _statusSteps = [
    'Pending',
    'Processing',
    'Out for Delivery',
    'Delivered'
  ];

  @override
  Widget build(BuildContext context) {
    int currentStep = _statusSteps.indexOf(_status);
    if (currentStep == -1)
      currentStep = 0; // Default to first step if status unknown

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Order Tracking',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildOrderInfoCard(),
              SizedBox(height: 20),
              _buildStepper(currentStep),
              SizedBox(height: 20),
              _buildDetailsCard(),
              SizedBox(height: 20),
              _buildItemsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.teal[700],
      shadowColor: Colors.grey[500],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${widget.orderId}',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            SizedBox(height: 5),
            Divider(color: Colors.white, thickness: 0.8),
            SizedBox(height: 5),
            Text(
              'Status: ${_status.toUpperCase()}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.grey[400],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          children: [
            Text(
              'Order Status',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700]),
            ),
            SizedBox(height: 10),
            Stepper(
              physics: NeverScrollableScrollPhysics(),
              currentStep: currentStep,
              steps: _statusSteps.map((step) {
                return Step(
                  title: Text(
                    step,
                    style: TextStyle(
                        color: Colors.teal[700], fontWeight: FontWeight.bold),
                  ),
                  content: SizedBox.shrink(),
                  isActive: _statusSteps.indexOf(step) <= currentStep,
                  state: _statusSteps.indexOf(step) < currentStep
                      ? StepState.complete
                      : _statusSteps.indexOf(step) == currentStep
                          ? StepState.editing
                          : StepState.indexed,
                );
              }).toList(),
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return SizedBox.shrink(); // Remove default controls
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.grey[400],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          children: [
            _buildDetailRow('Customer Name', _customerName, Icons.person),
            Divider(thickness: 1.2),
            _buildDetailRow('Total Amount',
                '₹${_totalAmount.toStringAsFixed(2)}', Icons.attach_money),
            Divider(thickness: 1.2),
            _buildAddressDetailRow(
                'Delivery Address', _address, Icons.location_on),
            Divider(thickness: 1.2),
            _buildDetailRow('Payment Method', _paymentMethod, Icons.payment),
            Divider(thickness: 1.2),
            _buildDetailRow('Assigned To', _assignedTo, Icons.person),
            if (_orderDate != null) Divider(thickness: 1.2),
            if (_orderDate != null)
              _buildDetailRow(
                'Order Date',
                '${_orderDate!.toDate().day}/${_orderDate!.toDate().month}/${_orderDate!.toDate().year} '
                    '${_orderDate!.toDate().hour}:${_orderDate!.toDate().minute}',
                Icons.calendar_today,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 5),
      leading: Icon(icon, color: Colors.teal[700]),
      title: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
      ),
      trailing: Text(
        value,
        style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
      ),
    );
  }

  Widget _buildAddressDetailRow(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 5),
      leading: Icon(icon, color: Colors.teal[700]),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.grey[400],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items in Order',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700]),
            ),
            Divider(thickness: 1.2),
            SizedBox(height: 10),
            ..._items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['quantity']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    // Adds spacing between item details and price
                    Text(
                      '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
