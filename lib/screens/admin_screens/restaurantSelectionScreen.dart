import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item_management_screen.dart';

class RestaurantSelectionScreen extends StatefulWidget {
  @override
  _RestaurantSelectionScreenState createState() =>
      _RestaurantSelectionScreenState();
}

class _RestaurantSelectionScreenState extends State<RestaurantSelectionScreen> {
  List<Map<String, String>> _restaurants = [];
  String? _selectedRestaurantId;
  String? _selectedRestaurantName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('restaurants').get();

      setState(() {
        _restaurants = querySnapshot.docs
            .map((doc) => {
          'id': doc.id,
          'name': doc['name'] as String,
        })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Failed to fetch restaurants: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Restaurant'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedRestaurantId,
              hint: Text('Select a Restaurant'),
              onChanged: (newValue) {
                setState(() {
                  _selectedRestaurantId = newValue;
                  _selectedRestaurantName = _restaurants
                      .firstWhere((element) => element['id'] == newValue)['name'];
                });
              },
              items: _restaurants.map<DropdownMenuItem<String>>((restaurant) {
                return DropdownMenuItem<String>(
                  value: restaurant['id'],
                  child: Text(restaurant['name']!),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _selectedRestaurantId == null
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuManagementScreen(
                    restaurantId: _selectedRestaurantId!,
                    restaurantName: _selectedRestaurantName!,
                  ),
                ),
              );
            },
            child: Text('Manage Menu Items'),
          ),
        ],
      ),
    );
  }
}
