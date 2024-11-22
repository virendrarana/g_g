// screens/edit_menu_item_screen.dart

import 'package:flutter/material.dart';
import 'package:g_g/models/menu_item_model.dart';
import 'package:g_g/services/menu_item_service.dart';


class EditMenuItemScreen extends StatefulWidget {
  final String restaurantId;
  final MenuItem menuItem;

  EditMenuItemScreen({
    required this.restaurantId,
    required this.menuItem,
  });

  @override
  _EditMenuItemScreenState createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuItemService _menuItemService = MenuItemService();

  late String _name;
  late String _description;
  late double _price;
  late String _imageUrl;
  late String _category;
  late bool _isAvailable;
  late String _type;

  final List<String> _categories = [
    'Appetizer',
    'Main Course',
    'Dessert',
    'Beverage',
    'Other',
  ];




  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.menuItem.name;
    _description = widget.menuItem.description;
    _price = widget.menuItem.price;
    _imageUrl = widget.menuItem.imageUrl;
    _category = widget.menuItem.category;
    _isAvailable = widget.menuItem.isAvailable;
    _type = widget.menuItem.type;
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    MenuItem updatedItem = MenuItem(
      id: widget.menuItem.id,
      name: _name,
      description: _description,
      price: _price,
      imageUrl: _imageUrl,
      category: _category,
      isAvailable: _isAvailable, type: _type,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await _menuItemService.updateMenuItem(widget.restaurantId, updatedItem);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item updated successfully!')),
      );
      Navigator.of(context).pop(); // Return to previous screen
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update menu item.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Menu Item'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name Field
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the name' : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              SizedBox(height: 10),
              // Description Field
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the description' : null,
                onSaved: (value) => _description = value!.trim(),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              // Price Field
              TextFormField(
                initialValue: _price.toString(),
                decoration: InputDecoration(labelText: 'Price (₹)'),
                keyboardType:
                TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter the price';
                  if (double.tryParse(value) == null)
                    return 'Please enter a valid number';
                  if (double.parse(value) <= 0)
                    return 'Price must be greater than zero';
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              SizedBox(height: 10),
              // Image URL Field
              TextFormField(
                initialValue: _imageUrl,
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the image URL' : null,
                onSaved: (value) => _imageUrl = value!.trim(),
              ),
              SizedBox(height: 10),
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
                onSaved: (value) => _category = value!,
              ),
              SizedBox(height: 10),
              // DropdownButtonFormField<String>(
              //   value: _type, // Use _type instead of _typecategories
              //   decoration: InputDecoration(labelText: 'Type'),
              //   items: _typecategories
              //       .map(
              //         (type) => DropdownMenuItem(
              //       value: type,
              //       child: Text(type),
              //     ),
              //   )
              //       .toList(),
              //   onChanged: (value) {
              //     setState(() {
              //       _type = value!;
              //     });
              //   },
              //   onSaved: (value) => _type = value!,
              // ),
              SizedBox(height: 10),
              // Availability Switch
              SwitchListTile(
                title: Text('Available'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
              SizedBox(height: 20),
              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Update Menu Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
