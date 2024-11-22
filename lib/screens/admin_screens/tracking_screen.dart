import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminTrackingScreen extends StatefulWidget {
  final String deliveryPartnerId;

  AdminTrackingScreen({required this.deliveryPartnerId});

  @override
  _AdminTrackingScreenState createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  GoogleMapController? mapController;
  LatLng _partnerLocation = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _trackDeliveryPartner();
  }

  void _trackDeliveryPartner() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.deliveryPartnerId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        GeoPoint location = data['location'];
        setState(() {
          _partnerLocation = LatLng(location.latitude, location.longitude);
        });
        mapController?.animateCamera(CameraUpdate.newLatLng(_partnerLocation));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Delivery Partner'),
        backgroundColor: Colors.teal,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _partnerLocation,
          zoom: 14.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('partnerLocation'),
            position: _partnerLocation,
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}
