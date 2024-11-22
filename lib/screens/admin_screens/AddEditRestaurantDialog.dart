import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';

class AddEditRestaurantDialog extends StatefulWidget {
  final Restaurant? restaurant;
  final Function(Restaurant) onSave;

  AddEditRestaurantDialog({this.restaurant, required this.onSave});

  @override
  _AddEditRestaurantDialogState createState() =>
      _AddEditRestaurantDialogState();
}

class _AddEditRestaurantDialogState extends State<AddEditRestaurantDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _address;
  late String _latitude;
  late String _longitude;
  late String _imageUrl;
  late String _cuisine;
  late double _rating;
  late String _videoUrl; // Add a new variable to store the video URL

  @override
  void initState() {
    super.initState();
    if (widget.restaurant != null) {
      _name = widget.restaurant!.name;
      _address = widget.restaurant!.address;
      final geoPoint = Restaurant.stringToGeoPoint(widget.restaurant!.geoPointString);
      _latitude = geoPoint.latitude.toString();
      _longitude = geoPoint.longitude.toString();
      _imageUrl = widget.restaurant!.imageUrl;
      _cuisine = widget.restaurant!.cuisine;
      _rating = widget.restaurant!.rating;
      _videoUrl = widget.restaurant!.videoUrl ?? ''; // Initialize with existing video URL if available
    } else {
      _name = '';
      _address = '';
      _latitude = '';
      _longitude = '';
      _imageUrl = '';
      _cuisine = '';
      _rating = 0.0;
      _videoUrl = ''; // Initialize to an empty string for new entries
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final geoPointString = Restaurant.geoPointToString(
          GeoPoint(double.parse(_latitude), double.parse(_longitude)));

      final restaurant = Restaurant(
        restaurantId: widget.restaurant?.restaurantId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        address: _address,
        geoPointString: geoPointString,
        imageUrl: _imageUrl,
        cuisine: _cuisine,
        rating: _rating,
        videoUrl: _videoUrl, // Add video URL to Restaurant object
      );

      widget.onSave(restaurant);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the name';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                TextFormField(
                  initialValue: _address,
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the address';
                    }
                    return null;
                  },
                  onSaved: (value) => _address = value!,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _latitude,
                        decoration: InputDecoration(labelText: 'Latitude'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the latitude';
                          }
                          return null;
                        },
                        onSaved: (value) => _latitude = value!,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _longitude,
                        decoration: InputDecoration(labelText: 'Longitude'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the longitude';
                          }
                          return null;
                        },
                        onSaved: (value) => _longitude = value!,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  initialValue: _imageUrl,
                  decoration: InputDecoration(labelText: 'Image URL'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the image URL';
                    }
                    return null;
                  },
                  onSaved: (value) => _imageUrl = value!,
                ),
                TextFormField(
                  initialValue: _cuisine,
                  decoration: InputDecoration(labelText: 'Cuisine'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the cuisine';
                    }
                    return null;
                  },
                  onSaved: (value) => _cuisine = value!,
                ),
                TextFormField(
                  initialValue: _rating.toString(),
                  decoration: InputDecoration(labelText: 'Rating'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the rating';
                    }
                    return null;
                  },
                  onSaved: (value) => _rating = double.parse(value!),
                ),
                TextFormField(
                  initialValue: _videoUrl,
                  decoration: InputDecoration(labelText: 'Video URL'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the video URL';
                    }
                    return null;
                  },
                  onSaved: (value) => _videoUrl = value!, // Save video URL
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _save,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
