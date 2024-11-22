import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String couponId;
  final String code;
  final double discountPercentage;
  final Timestamp expirationDate;

  Coupon({
    required this.couponId,
    required this.code,
    required this.discountPercentage,
    required this.expirationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': couponId,
      'code': code,
      'discountPercentage': discountPercentage,
      'expirationDate': expirationDate,
    };
  }

  factory Coupon.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      couponId: doc.id,
      code: data['code'],
      discountPercentage: data['discountPercentage'].toDouble(),
      expirationDate: data['expirationDate'],
    );
  }
}
