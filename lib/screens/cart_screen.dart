import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:g_g/models/cart_model.dart';
import 'package:provider/provider.dart';
import 'package:g_g/services/cart_service.dart';
import 'package:g_g/screens/checkout_screen.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isPremiumCustomer = false;

  static const Color Tile_color = Color.fromRGBO(250, 248, 246, 1);
  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
  static const Color button_in_color = Color.fromRGBO(193, 212, 192, 1);
  static const Color user_tile_color = Color.fromRGBO(211, 211, 211, 1);

  @override
  void initState() {
    super.initState();
    checkIfPremiumCustomer();
  }

  // Function to check if the customer is premium by fetching the `isPremium` value from Firestore
  Future<void> checkIfPremiumCustomer() async {
    try {
      // Replace this with the actual user ID
      final userId = "user-id";
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data()!['isPremium'] == true) {
        setState(() {
          isPremiumCustomer = true;
        });
      }
    } catch (e) {
      print('Error checking premium status: $e');
      Fluttertoast.showToast(
        msg: 'Error checking premium status',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showClearCartConfirmation(cart),
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
        child: Text(
          'Your cart is empty',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _buildCartItem(context, cart, item);
              },
            ),
          ),
          _buildCheckoutButton(context, cart),
        ],
      ),
    );
  }


  // Function to show a confirmation dialog before clearing the cart
  void _showClearCartConfirmation(Cart cart) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Empty Cart"),
          content: Text("Are you sure you want to empty your cart?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                cart.clear(); // Clear the cart
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Empty Cart", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(BuildContext context, Cart cart, CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Item Name and Additional Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),

                        // Price
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        SizedBox(height: 4),

                        // Additional Info (e.g., recipe type, spice level)
                        Text(
                          'Classic Recipe (Mild Spicy)',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 6),
                      ],
                    ),
                  ),

                  // Quantity and Total Price Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Quantity Selector
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: button_in_color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: button_color, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (item.quantity == 1) {
                                  // Show confirmation dialog if quantity is 1
                                  _showRemoveConfirmation(context, cart, item);
                                } else {
                                  cart.removeItem(item.id);
                                }
                              },
                              child: Icon(Icons.remove, color: button_color, size: 18),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${item.quantity}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: button_color),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                cart.addItem(item);
                              },
                              child: Icon(Icons.add, color: button_color, size: 18),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),

                      // Total Price for this item
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, Cart cart, CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Remove Item"),
          content: Text("Are you sure you want to remove this item from the cart?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                cart.removeItem(item.id); // Remove the item from the cart
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Remove", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  Widget _buildYouMayAlsoLike() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You May Also Like',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRecommendedItem('https://via.placeholder.com/100', 'Item 1', '₹100'),
                _buildRecommendedItem('https://via.placeholder.com/100', 'Item 2', '₹150'),
                _buildRecommendedItem('https://via.placeholder.com/100', 'Item 3', '₹200'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedItem(String imageUrl, String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 8),
          Text(name, style: TextStyle(fontSize: 14)),
          Text(price, style: TextStyle(fontSize: 14, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildCouponsAndCredits(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () async {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => FutureBuilder(
              future: FirebaseFirestore.instance.collection('coupons').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No coupons available',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Coupons',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final coupon = snapshot.data!.docs[index].data();
                            return _buildCouponCard(context, coupon);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
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
                Icons.percent,
                color: Colors.black,
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

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> coupon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            coupon['code'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${coupon['discountPercentage']}% off',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          trailing: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: 'Coupon ${coupon['code']} applied',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.teal,
                textColor: Colors.white,
              );
            },
            child: Text(
              'Apply',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillDetails(Cart cart) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching premium status'));
        }

        // Check if the user is premium
        bool isPremiumCustomer = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          isPremiumCustomer = snapshot.data!['isPremium'] ?? false;
        }

        // Define the individual fees and charges
        final deliveryServiceCharge = isPremiumCustomer ? 0.0 : cart.totalAmount * 0.05; // 5% delivery charge if not premium
        final packagingServiceCharge = cart.totalAmount * 0.05; // 5% packaging charge

        // Example values for discount and wallet points used
        final _discount = 10.0; // Replace with actual discount logic
        final _walletPointsUsed = 20.0; // Replace with actual wallet points logic

        // Calculate the final payable amount
        final _finalAmount = cart.totalAmount - _discount - _walletPointsUsed + deliveryServiceCharge + packagingServiceCharge;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BILL DETAILS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              _buildBillRow('Subtotal', '₹${cart.totalAmount.toStringAsFixed(2)}'),
              _buildBillRow('Discount', '- ₹${_discount.toStringAsFixed(2)}', color: Colors.green),
              _buildBillRow('Wallet Points Used', '- ₹${_walletPointsUsed.toStringAsFixed(2)}', color: Colors.blue),
              _buildBillRow(
                'Delivery Service (5%)',
                isPremiumCustomer ? 'Free' : '+ ₹${deliveryServiceCharge.toStringAsFixed(2)}',
                color: Colors.orange,
              ),
              _buildBillRow(
                'Packaging Service (5%)',
                '+ ₹${packagingServiceCharge.toStringAsFixed(2)}',
                color: Colors.orange,
              ),
              Divider(thickness: 1.5),
              SizedBox(height: 5),
              _buildBillRow(
                'Total Payable',
                '₹${_finalAmount.toStringAsFixed(2)}',
                isBold: true,
                fontSize: 18,
                color: Colors.teal,
              ),
            ],
          ),
        );
      },
    );
  }

// Helper function to build each row in bill details with optional color, bold text, and underline link
  Widget _buildBillRow(String title, String amount,
      {bool isBold = false, bool isLink = false, Color color = Colors.black87, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: isLink ? () => print('Show GST details') : null, // Link action for GST
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isLink ? Colors.blueAccent : color,
                decoration: isLink ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCheckoutButton(BuildContext context, Cart cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(
                  totalAmount: cart.totalAmount,
                  cartItems: cart.items.map((item) => item.toMap()).toList(),
                ),
              ),
            );
          },
          child: Text(
            'Proceed to Checkout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
