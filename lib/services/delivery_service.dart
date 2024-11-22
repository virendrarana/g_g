import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryPartnerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updateLocation() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
      });
    }
  }

  void startTracking() {
    Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        )).listen((Position position) {
      updateLocation();
    });
  }
}
