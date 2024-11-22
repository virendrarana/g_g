import 'package:flutter/material.dart';
import 'package:g_g/screens/admin_screens/AddEditRestaurantDialog.dart';
import 'package:g_g/models/restaurant_model.dart';
import 'package:g_g/services/restaurant_service.dart';

class RestaurantManagementScreen extends StatefulWidget {
  @override
  _RestaurantManagementScreenState createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends State<RestaurantManagementScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isLoading = true;
    });
    _restaurants = await _restaurantService.getAllRestaurants();
    setState(() {
      _isLoading = false;
    });
  }

  void _addOrEditRestaurant({Restaurant? restaurant}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEditRestaurantDialog(
          restaurant: restaurant,
          onSave: (Restaurant updatedRestaurant) async {
            if (restaurant == null) {
              // Add new restaurant
              await _restaurantService.addRestaurant(updatedRestaurant);
            } else {
              // Edit existing restaurant
              await _restaurantService.updateRestaurant(updatedRestaurant);
            }
            _fetchRestaurants();
          },
        );
      },
    );
  }

  void _deleteRestaurant(String id) async {
    await _restaurantService.deleteRestaurant(id);
    _fetchRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Management'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          return ListTile(
            title: Text(restaurant.name),
            subtitle: Text(restaurant.address),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _addOrEditRestaurant(restaurant: restaurant),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteRestaurant(restaurant.restaurantId),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditRestaurant(),
        child: Icon(Icons.add),
      ),
    );
  }
}
