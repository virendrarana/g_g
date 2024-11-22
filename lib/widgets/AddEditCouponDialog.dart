import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:g_g/models/coupon_model.dart';


class AddEditCouponDialog extends StatefulWidget {
  final Coupon? coupon;
  final Function(Coupon) onSave;

  AddEditCouponDialog({this.coupon, required this.onSave});

  @override
  _AddEditCouponDialogState createState() => _AddEditCouponDialogState();
}

class _AddEditCouponDialogState extends State<AddEditCouponDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _code;
  late double _discountPercentage;
  late DateTime _expirationDate;

  @override
  void initState() {
    super.initState();
    if (widget.coupon != null) {
      _code = widget.coupon!.code;
      _discountPercentage = widget.coupon!.discountPercentage;
      _expirationDate = widget.coupon!.expirationDate.toDate();
    } else {
      _code = '';
      _discountPercentage = 0.0;
      _expirationDate = DateTime.now();
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final coupon = Coupon(
        couponId: widget.coupon?.couponId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        code: _code,
        discountPercentage: _discountPercentage,
        expirationDate: Timestamp.fromDate(_expirationDate),
      );

      widget.onSave(coupon);
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
                  initialValue: _code,
                  decoration: InputDecoration(labelText: 'Coupon Code'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the coupon code';
                    }
                    return null;
                  },
                  onSaved: (value) => _code = value!,
                ),
                TextFormField(
                  initialValue: _discountPercentage.toString(),
                  decoration: InputDecoration(labelText: 'Discount Percentage'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the discount percentage';
                    }
                    return null;
                  },
                  onSaved: (value) => _discountPercentage = double.parse(value!),
                ),
                ListTile(
                  title: Text("Expiration Date: ${_expirationDate.toLocal()}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: _pickDate,
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

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _expirationDate) {
      setState(() {
        _expirationDate = pickedDate;
      });
    }
  }
}
