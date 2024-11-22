import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePromoScreen extends StatefulWidget {
  @override
  _CreatePromoScreenState createState() => _CreatePromoScreenState();
}

class _CreatePromoScreenState extends State<CreatePromoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _code = '';
  double _discountPercentage = 0.0;
  DateTime _expirationDate = DateTime.now();

  Future<void> _createPromoCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    try {
      final userId = _auth.currentUser!.uid;
      await FirebaseFirestore.instance.collection('coupons').add({
        'code': _code,
        'discountPercentage': _discountPercentage,
        'expirationDate': _expirationDate,
        'createdBy': userId,
        'usageCount': 0,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Promo code created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create promo code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Promo Code'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Promo Code'),
                validator: (value) => value!.isEmpty ? 'Enter a promo code' : null,
                onSaved: (value) => _code = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Discount Percentage'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter discount percentage' : null,
                onSaved: (value) => _discountPercentage = double.parse(value!),
              ),
              SizedBox(height: 16),
              Text('Expiration Date'),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _expirationDate = selectedDate;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_expirationDate.toLocal().toString().split(' ')[0]),
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: _createPromoCode,
                child: Text('Create Promo Code'),
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
