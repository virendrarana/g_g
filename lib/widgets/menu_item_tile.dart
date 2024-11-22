// menu_item_tile.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemTile extends StatefulWidget {
  final String imageUrl;
  final String name;
  final double price;
  final VoidCallback onAddToCart;

  MenuItemTile({
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.onAddToCart,
  });

  @override
  _MenuItemTileState createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<MenuItemTile> {
  bool? premiumStatus; // null indicates loading state
  String? _errorMessage; // To store any error messages

  @override
  void initState() {
    super.initState();
    _fetchPremiumStatus();
  }

  // Fetch the premium status of the current user
  Future<void> _fetchPremiumStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not authenticated.');
        // If user is not logged in, treat as non-premium
        setState(() {
          premiumStatus = false;
        });
        return;
      }

      print('Fetching premiumStatus for user: ${user.uid}');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        bool premiumStatus = userDoc.get('premiumStatus') ?? false;
        print('premiumStatus fetched: $premiumStatus');
        setState(() {
          premiumStatus = premiumStatus;
        });
      } else {
        print('User document does not exist.');
        setState(() {
          premiumStatus = false;
        });
      }
    } catch (e) {
      // Handle errors appropriately
      print('Error fetching premium status: $e');
      setState(() {
        premiumStatus = false;
        _errorMessage = 'Failed to fetch premium status.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate discounted price
    double discountedPrice = widget.price * 0.85; // 15% discount

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              widget.imageUrl,
              height: 80.0,
              width: 80.0,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 80.0,
                  width: 80.0,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                print('Error loading image: $exception');
                return Container(
                  height: 80.0,
                  width: 80.0,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40.0,
                    semanticLabel: 'Image not available',
                  ),
                );
              },
            ),
          ),
          // Item Details
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  // Pricing and Discount Info
                  premiumStatus == null
                      ? SizedBox(
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.teal,
                    ),
                  )
                      : _errorMessage != null
                      ? Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.red,
                    ),
                  )
                      : premiumStatus!
                      ? Row(
                    children: [
                      // Original Price with Strikethrough
                      Text(
                        '₹${widget.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Discounted Price
                      Text(
                        '₹${discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : Row(
                    children: [
                      // Original Price
                      Text(
                        '₹${widget.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Upgrade Prompt
                      Expanded(
                        child: Text(
                          'Get 15% off by upgrading to Premium!',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.blueAccent,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Add to Cart Button
          IconButton(
            icon: Icon(
              Icons.add_shopping_cart,
              color: Colors.teal,
            ),
            onPressed: widget.onAddToCart,
            tooltip: 'Add to Cart',
          ),
        ],
      ),
    );
  }
}
