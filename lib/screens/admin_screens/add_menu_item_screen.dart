import 'package:flutter/material.dart';
import 'package:g_g/models/menu_item_model.dart';
import 'package:g_g/services/menu_item_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  final String restaurantId;

  AddMenuItemScreen({required this.restaurantId});

  @override
  _AddMenuItemScreenState createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuItemService _menuItemService = MenuItemService();

  String _name = '';
  String _description = '';
  double? _price; // Base price for single size items
  String _imageUrl = '';
  String _category = 'Rice Bowl';
  bool _isAvailable = true;
  bool _supportsPortionSizes = false; // Field for enabling portion sizes
  String _type = 'Veg';

  // Portion sizes and prices
  final Map<String, double> _portionSizes = {};
  final TextEditingController _portionNameController = TextEditingController();
  final TextEditingController _portionPriceController = TextEditingController();

  final List<String> _categories = [
    'Rice Bowl',
    'Main Course',
    'Bread & Rice',
    'Veggie Salad',
    'Mushroom Salad',
    'High Protein Bowl',
    'Protein Delight Bowl',
    'Veg Biryani',
    'Non-Veg Biryani',
    'Veg Kepsa',
    'Non-Veg Kepsa',
    'Veg Starters',
    'Non-Veg Starters',
    'Veg Rice/Noodles',
    'Non-Veg Rice/Noodles',
  ];

  final List<String> _typecategories = ['Veg', 'Non-Veg', 'Egg'];

  bool _isLoading = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    MenuItem newItem = MenuItem(
      name: _name,
      description: _description,
      price: _supportsPortionSizes ? 0.0 : _price ?? 0.0, // Set base price
      imageUrl: _imageUrl,
      category: _category,
      isAvailable: _isAvailable,
      type: _type,
      supportsPortionSizes: _supportsPortionSizes,
      portionSizes: _supportsPortionSizes ? _portionSizes : null,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await _menuItemService.addMenuItem(widget.restaurantId, newItem);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item added successfully!')),
      );
      Navigator.of(context).pop(); // Return to previous screen
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add menu item.')),
      );
    }
  }

  void _addPortionSize() {
    final String portionName = _portionNameController.text.trim();
    final String portionPrice = _portionPriceController.text.trim();

    if (portionName.isEmpty || portionPrice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide both portion name and price.')),
      );
      return;
    }

    final double? price = double.tryParse(portionPrice);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a valid price.')),
      );
      return;
    }

    setState(() {
      _portionSizes[portionName] = price;
    });

    _portionNameController.clear();
    _portionPriceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Menu Item'),
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
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the name' : null,
                onSaved: (value) => _name = value!.trim(),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty
                    ? 'Please enter the description'
                    : null,
                onSaved: (value) => _description = value!.trim(),
                maxLines: 3,
              ),
              SizedBox(height: 10),

              // Price Field (Conditional)
              if (!_supportsPortionSizes)
                TextFormField(
                  decoration: InputDecoration(labelText: 'Price (₹)'),
                  keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter the price';
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Price must be greater than zero';
                    }
                    return null;
                  },
                  onSaved: (value) => _price = double.parse(value!),
                ),

              if (_supportsPortionSizes) ...[
                // Portion Sizes Management
                Text(
                  'Portion Sizes',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: _portionSizes.entries
                      .map((entry) => ListTile(
                    title: Text(entry.key),
                    trailing: Text('₹${entry.value.toString()}'),
                    leading: Icon(Icons.fastfood),
                    onLongPress: () {
                      setState(() {
                        _portionSizes.remove(entry.key);
                      });
                    },
                  ))
                      .toList(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _portionNameController,
                        decoration: InputDecoration(
                          labelText: 'Portion Name',
                          hintText: 'e.g., Serves 1-2',
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _portionPriceController,
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price (₹)',
                          hintText: 'e.g., 100.0',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.teal),
                      onPressed: _addPortionSize,
                    ),
                  ],
                ),
              ],

              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the image URL' : null,
                onSaved: (value) => _imageUrl = value!.trim(),
              ),
              SizedBox(height: 10),
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
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: 'Type'),
                items: _typecategories
                    .map(
                      (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
                onSaved: (value) => _type = value!,
              ),
              SizedBox(height: 10),
              SwitchListTile(
                title: Text('Available'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
              SizedBox(height: 10),

              // Switch for portion sizes
              SwitchListTile(
                title: Text('Supports Portion Sizes'),
                value: _supportsPortionSizes,
                onChanged: (value) {
                  setState(() {
                    _supportsPortionSizes = value;
                    _portionSizes.clear();
                  });
                },
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Add Menu Item'),
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
