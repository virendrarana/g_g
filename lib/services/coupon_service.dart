import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_g/models/coupon_model.dart';

class CouponService {
  final CollectionReference _couponCollection =
  FirebaseFirestore.instance.collection('coupons');

  // Get all coupons from Firestore
  Future<List<Coupon>> getAllCoupons() async {
    try {
      QuerySnapshot querySnapshot = await _couponCollection.get();
      return querySnapshot.docs
          .map((doc) => Coupon.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Failed to get coupons: $e");
      return [];
    }
  }

  // Add a new coupon to Firestore
  Future<void> addCoupon(Coupon coupon) async {
    try {
      await _couponCollection.add(coupon.toMap());
      print("Coupon added successfully!");
    } catch (e) {
      print("Failed to add coupon: $e");
    }
  }

  // Update an existing coupon in Firestore
  Future<void> updateCoupon(Coupon coupon) async {
    try {
      await _couponCollection.doc(coupon.couponId).update(coupon.toMap());
      print("Coupon updated successfully!");
    } catch (e) {
      print("Failed to update coupon: $e");
    }
  }

  // Delete a coupon from Firestore
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _couponCollection.doc(couponId).delete();
      print("Coupon deleted successfully!");
    } catch (e) {
      print("Failed to delete coupon: $e");
    }
  }
}
