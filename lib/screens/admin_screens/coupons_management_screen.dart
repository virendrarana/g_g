import 'package:flutter/material.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import '../../widgets/AddEditCouponDialog.dart';

class CouponManagementScreen extends StatefulWidget {
  @override
  _CouponManagementScreenState createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  final CouponService _couponService = CouponService();
  List<Coupon> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  // Fetch all coupons from Firestore
  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _coupons = await _couponService.getAllCoupons();
    } catch (e) {
      // Handle any errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load coupons: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show Add/Edit Coupon Dialog
  void _addOrEditCoupon({Coupon? coupon}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEditCouponDialog(
          coupon: coupon,
          onSave: (Coupon updatedCoupon) async {
            try {
              if (coupon == null) {
                await _couponService.addCoupon(updatedCoupon);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon added successfully!')),
                );
              } else {
                await _couponService.updateCoupon(updatedCoupon);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon updated successfully!')),
                );
              }
              _fetchCoupons();
            } catch (e) {
              // Handle any errors during add/edit
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Operation failed: $e')),
              );
            }
          },
        );
      },
    );
  }

  // Show Confirmation Dialog before Deleting Coupon
  Future<void> _confirmDeleteCoupon(String couponId) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Coupon'),
          content: Text('Are you sure you want to delete this coupon?'),
          actions: [
            TextButton(
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red color for delete action
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deleteCoupon(couponId);
    }
  }

  // Delete Coupon from Firestore
  void _deleteCoupon(String couponId) async {
    try {
      await _couponService.deleteCoupon(couponId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon deleted successfully!')),
      );
      _fetchCoupons();
    } catch (e) {
      // Handle any errors during deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deletion failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coupon Management'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
          ? Center(child: Text('No coupons available.'))
          : ListView.builder(
        itemCount: _coupons.length,
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text('Code: ${coupon.code}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Discount: ${coupon.discountPercentage}%'),
                  SizedBox(height: 2),
                  Text(
                      'Expires on: ${coupon.expirationDate.toDate().toLocal().toString().split(' ')[0]}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _addOrEditCoupon(coupon: coupon),
                    tooltip: 'Edit Coupon',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmDeleteCoupon(coupon.couponId),
                    tooltip: 'Delete Coupon',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCoupon(),
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: 'Add Coupon',
      ),
    );
  }
}
