import 'package:flutter/material.dart';

class CartItemWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final int quantity;
  final double price;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onRemove;

  CartItemWidget({
    required this.imageUrl,
    required this.name,
    required this.quantity,
    required this.price,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.network(
              imageUrl,
              height: 80.0,
              width: 80.0,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    '₹$price',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: onDecreaseQuantity,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: onIncreaseQuantity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onRemove,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
