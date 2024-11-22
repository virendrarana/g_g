import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelectionPage extends StatefulWidget {
  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final TextEditingController _manualAddressController =
  TextEditingController();
  String _addressLabel = 'home'; // Default label for addresses

  Future<void> _saveAddress(String address, {String label = 'home'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_addresses')
          .add({
        'address': address,
        'label': label,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context, {'address': address, 'label': label});
    }
  }

  Future<void> _fetchAndSaveCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address =
            "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}";

        await _saveAddress(address, label: _addressLabel);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch location: $e')),
      );
    }
  }

  void _showManualAddressInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Address Manually'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _manualAddressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Enter your address",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _addressLabel,
                onChanged: (String? newValue) {
                  setState(() {
                    _addressLabel = newValue!;
                  });
                },
                items: <String>['home', 'office', 'others']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                String address = _manualAddressController.text.trim();
                if (address.isNotEmpty) {
                  await _saveAddress(address, label: _addressLabel);
                  Navigator.of(context).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Address saved successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter an address')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search for area, society name...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              Icon(Icons.close, color: Colors.black),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.gps_fixed, color: Colors.black),
              title: Text(
                "Use Current Location",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _fetchAndSaveCurrentLocation(),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "SAVED ADDRESSES",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('saved_addresses')
                    .orderBy('timestamp', descending: true)
                    .snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No saved addresses.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>?;

                      return ListTile(
                        leading: Icon(
                          data != null && data.containsKey('label') && data['label'] == 'home'
                              ? Icons.home
                              : data != null && data.containsKey('label') && data['label'] == 'office'
                              ? Icons.work
                              : Icons.location_on,
                          color: Colors.black,
                        ),
                        title: Text(data?['label'] ?? 'Unknown'),
                        subtitle: Text(data?['address'] ?? 'No address available'),
                        onTap: () {
                          Navigator.pop(
                            context,
                            {
                              'address': data?['address'] ?? 'No address available',
                              'label': data?['label'] ?? 'others',
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualAddressInputDialog(),
        label: Text('Add Address'),
        icon: Icon(Icons.add_location),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
