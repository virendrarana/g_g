import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CouponUsageScreen extends StatelessWidget {
  final String promoterId;

  CouponUsageScreen({required this.promoterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Coupon Usage'), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promo_codes')
            .where('createdBy', isEqualTo: promoterId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final codes = snapshot.data!.docs;
          return ListView.builder(
            itemCount: codes.length,
            itemBuilder: (context, index) {
              var promoData = codes[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(promoData['code']),
                subtitle: Text('Used ${promoData['usageCount']} times'),
              );
            },
          );
        },
      ),
    );
  }
}
