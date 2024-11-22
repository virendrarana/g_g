import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_g/screens/address_entry_page.dart';
import 'package:g_g/screens/order_confirmation_page.dart';
import 'package:g_g/screens/payments/payment_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:g_g/services/cart_service.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;

  CheckoutScreen({required this.totalAmount, required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  String _paymentMethod = 'UPI';
  String _couponCode = '';
  double _discount = 0.0;
  double _finalAmount = 0.0;
  int _walletPointsUsed = 0;
  int _walletBalance = 0;
  String _customerName = '';
  String _contactNumber = '';
  String? _assignedTo;
  bool _isPremiumCustomer = false;

  // New Variables for Additional Charges
  double _deliveryServiceCharge = 0.0;
  double _packagingServiceCharge = 0.0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.totalAmount;
    _fetchUserData(); // Fetch customer name and contact number
    _fetchWalletBalance();
    _fetchAvailableCoupons();
  }

  // Fetch the user's wallet balance from Firestore
  void _fetchWalletBalance() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot walletSnapshot = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId)
          .get();

      if (walletSnapshot.exists) {
        setState(() {
          _walletBalance = walletSnapshot['points'] ?? 0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch wallet balance: $e')),
      );
    }
  }

  // Fetch customer name and contact number from Firestore
  void _fetchUserData() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _customerName = userSnapshot['fullName'] ?? '';
          _contactNumber = userSnapshot['contactNumber'] ?? '';
          _isPremiumCustomer = userSnapshot['isPremium'] ?? false; // Check premium status
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
    }
  }


  // Generate a random 6-digit order ID
  String _generateOrderId() {
    final random = Random();
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    // Generate random letters
    String randomLetters = String.fromCharCodes(
      Iterable.generate(3, (_) => letters.codeUnitAt(random.nextInt(letters.length))),
    );
    // Generate random number (6 digits)
    int randomNumber = random.nextInt(900000) + 100000;
    // Combine timestamp, random letters, and random number
    String uniqueTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$randomLetters-$randomNumber-$uniqueTimestamp';
  }


  Future<List<Map<String, dynamic>>> _fetchAvailableCoupons() async {
    try {
      final QuerySnapshot couponSnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('expirationDate', isGreaterThan: DateTime.now()) // Ensure only valid coupons are shown
          .get();

      return couponSnapshot.docs.map((doc) {
        return {
          'code': doc['code'],
          'discountPercentage': doc['discountPercentage'],
          'expirationDate': doc['expirationDate'],
        };
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch available coupons: $e')),
      );
      return [];
    }
  }

  Future<void> _showCouponSelection() async {
    List<Map<String, dynamic>> availableCoupons = await _fetchAvailableCoupons();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Coupon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: availableCoupons.length,
                  itemBuilder: (context, index) {
                    var coupon = availableCoupons[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          title: Text(
                            coupon['code'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${coupon['discountPercentage']}% off',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Apply the selected coupon
                              setState(() {
                                _couponCode = coupon['code'];
                                _discount = widget.totalAmount *
                                    (coupon['discountPercentage'] / 100);
                                _recalculateFinalAmount();
                              });
                              Navigator.pop(context); // Close the popup
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                  Text('Coupon ${coupon['code']} applied!'),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Recalculate final amount including delivery and packaging charges
  void _recalculateFinalAmount() {
    double baseAmount = widget.totalAmount - _discount - _walletPointsUsed;

    // Apply charges based on premium status
    _deliveryServiceCharge = _isPremiumCustomer ? 0.0 : baseAmount * 0.05; // Free if premium
    _packagingServiceCharge = _isPremiumCustomer ? 0.0 : baseAmount * 0.05; // Free if premium

    _finalAmount = baseAmount + _deliveryServiceCharge + _packagingServiceCharge;
  }


  // Place order logic
  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      final String userId = FirebaseAuth.instance.currentUser!.uid;
      String orderId = _generateOrderId();

      int rewardPoints = (_finalAmount * 0.02).round();

      try {
        WriteBatch batch = FirebaseFirestore.instance.batch();

        DocumentReference walletRef = FirebaseFirestore.instance.collection('wallets').doc(userId);
        DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
        DocumentReference cartRef = FirebaseFirestore.instance.collection('carts').doc(userId);

        // Update wallet points
        batch.update(walletRef, {
          'points': FieldValue.increment(-_walletPointsUsed + rewardPoints),
          'transactionHistory': FieldValue.arrayUnion([
            {
              'description': 'Order #$orderId',
              'pointsAdded': -_walletPointsUsed,
              'timestamp': Timestamp.now(),
            },
            {
              'description': 'Reward for Order #$orderId',
              'pointsAdded': rewardPoints,
              'timestamp': Timestamp.now(),
            },
          ]),
        });

        // Create the new order
        batch.set(orderRef, {
          'orderId': orderId,
          'userId': userId,
          'customerName': _customerName,
          'contactNumber': _contactNumber,
          'orderDate': Timestamp.now(),
          'updatedAt': FieldValue.serverTimestamp(),
          'totalAmount': _finalAmount,
          'address': _addressController.text.trim(),
          'assignedTo': _assignedTo,
          'paymentMethod': _paymentMethod,
          'status': 'Pending',
          'walletPointsUsed': _walletPointsUsed,
          'discountApplied': _discount,
          'deliveryServiceCharge': _deliveryServiceCharge,
          'packagingServiceCharge': _packagingServiceCharge,
          'items': widget.cartItems,
        });

        // Clear the user's cart in Firestore
        batch.delete(cartRef);

        // Commit the batch operation
        await batch.commit();

        // Clear the cart locally
        final cart = Provider.of<Cart>(context, listen: false);
        cart.clearCart(); // Ensure the cart is emptied after successful order placement

        // Navigate to the order confirmation screen
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                OrderConfirmationScreen(
              orderId: orderId,
              totalAmount: _finalAmount,
              deliveryTime: '30 mins',
              restaurantName: 'G G Restaurant',
            )
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // Function to apply wallet points
  void _applyWalletPoints(int points) {
    setState(() {
      _walletPointsUsed = points > _walletBalance ? _walletBalance : points;
      _recalculateFinalAmount();
    });
  }
  // Function to fetch current location and convert to address
  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String formattedAddress =
            '${placemark.name}, ${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
        setState(() {
          _addressController.text = formattedAddress; // Update the controller text
          _recalculateFinalAmount();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address fetched from current location.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch address from location.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildOrderSummary(),
                        SizedBox(height: 20),
                        _buildCouponField(),
                        SizedBox(height: 20),
                        _buildWalletPointsField(),
                        SizedBox(height: 20),
                        _buildEstimatedDeliveryTime(),
                        SizedBox(height: 20),
                        _buildAddressSection(),
                        SizedBox(height: 20),
                        //_buildPaymentOptions(),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 15), // Remove horizontal padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Center( // Wrap with Center to ensure the text is centered
                      child: Text(
                        'Place Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildEstimatedDeliveryTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time, // Icon for estimated delivery time
              color: button_color,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Estimated Delivery Time: 30 mins', // Example delivery time text
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }


  static const Color Tile_color = Color.fromRGBO(250, 248, 246, 1);
  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
  static const Color button_in_color = Color.fromRGBO(193, 212, 192, 1);
  static const Color user_tile_color = Color.fromRGBO(211, 211, 211, 1);


  Widget _buildOrderSummary() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ...widget.cartItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['quantity']}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
            Divider(thickness: 1.5),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: TextStyle(fontSize: 16)),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount', style: TextStyle(fontSize: 16, color: Colors.green)),
                Text(
                  '- ₹${_discount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wallet Points Used', style: TextStyle(fontSize: 16, color: Colors.blue)),
                Text(
                  '- ₹${_walletPointsUsed.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Service (5%)',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Text(
                  _isPremiumCustomer ? 'Free' : '+ ₹${_deliveryServiceCharge.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Packaging Service (5%)',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Text(
                  _isPremiumCustomer ? 'Free' : '+ ₹${_packagingServiceCharge.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
            Divider(thickness: 1.5),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  '₹${_finalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () async {
          // Navigate to the new address entry page and wait for the result (selected address)
          final selectedAddress = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddressEntryPage(),
            ),
          );

          // Update the address controller with the selected address
          if (selectedAddress != null) {
            setState(() {
              _addressController.text = selectedAddress;
            });
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  _addressController.text.isNotEmpty
                      ? _addressController.text
                      : 'Enter Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.teal[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text('UPI'),
              leading: Radio<String>(
                value: 'UPI',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Credit/Debit Card'),
              leading: Radio<String>(
                value: 'Card',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Cash on Delivery'),
              leading: Radio<String>(
                value: 'COD',
                groupValue: _paymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: _isLoading ? null : _showCouponSelection,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.percent,
                color: Colors.cyan,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Apply Promo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletPointsField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            // Toggle wallet points usage
            if (_walletPointsUsed > 0) {
              _walletPointsUsed = 0; // Reset if already applied
            } else {
              _walletPointsUsed = (_walletBalance * 0.2).round(); // Apply 20% of wallet balance as discount
            }
            _recalculateFinalAmount(); // Recalculate the final amount after applying/removing points
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.orangeAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use Wallet Points (${_walletBalance} available)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _walletPointsUsed > 0 ? 'Applied' : 'Apply',
                style: TextStyle(
                  fontSize: 16,
                  color: _walletPointsUsed > 0 ? Colors.green : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

}



