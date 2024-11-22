// screens/menu_management_screen.dart

import 'package:flutter/material.dart';
import 'package:g_g/models/menu_item_model.dart';
import 'package:g_g/services/menu_item_service.dart';

import 'add_menu_item_screen.dart';
import 'edit_menu_item_screen.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  MenuManagementScreen({
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  _MenuManagementScreenState createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuItemService _menuItemService = MenuItemService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.restaurantName} - Menu'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: _menuItemService.streamMenuItemsByRestaurant(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching menu items.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final menuItems = snapshot.data!;

          if (menuItems.isEmpty) {
            return Center(child: Text('No menu items found.'));
          }

          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              var item = menuItems[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: item.imageUrl.isNotEmpty
                      ? Image.network(
                    item.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image, color: Colors.grey);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator();
                    },
                  )
                      : CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      item.name.isNotEmpty ? item.name[0].toUpperCase() : 'M',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text('\₹${item.price.toStringAsFixed(2)}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        // Navigate to Edit Menu Item Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMenuItemScreen(
                              restaurantId: widget.restaurantId,
                              menuItem: item,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        // Confirm and delete the menu item
                        _confirmDeleteMenuItem(item.id!);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Menu Item Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMenuItemScreen(
                restaurantId: widget.restaurantId,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: 'Add Menu Item',
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a menu item
  void _confirmDeleteMenuItem(String menuItemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Menu Item'),
          content: Text('Are you sure you want to delete this menu item?'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                try {
                  await _menuItemService.deleteMenuItem(
                      widget.restaurantId, menuItemId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Menu item deleted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete menu item.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
