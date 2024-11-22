import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_g/screens/payments/payment_screen.dart';

class PremiumMembershipPage extends StatefulWidget {
  @override
  _PremiumMembershipPageState createState() => _PremiumMembershipPageState();
}

class _PremiumMembershipPageState extends State<PremiumMembershipPage> {
  bool _isLoading = true;
  bool _isPremium = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  // Check if the user is a premium member or not
  Future<void> _checkPremiumStatus() async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (snapshot.exists && snapshot['isPremium'] == true) {
        setState(() {
          _isLoading = false;
          _isPremium = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isPremium = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _isPremium = false;
      });
      print("Error checking premium status: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isPremium
          ? _buildPremiumMemberContent()
          : _buildPremiumOffer(context),
    );
  }

  // UI for Premium Members
  Widget _buildPremiumMemberContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 100,
            color: Colors.amber,
          ),
          SizedBox(height: 20),
          Text(
            "You are a Premium Member!",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          SizedBox(height: 10),
          Text(
            "Enjoy exclusive benefits like discounts and free delivery.",
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // UI for non-premium users to buy membership
  Widget _buildPremiumOffer(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildPremiumCard(),
          ),
          SizedBox(height: 50),
          _buildBenefitsSection(),
          SizedBox(height: 50),
          _buildBuyButton(context),
        ],
      ),
    );
  }

  // Premium offer card
  Widget _buildPremiumCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow[700]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Become a Premium Member",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Get exclusive discounts, free delivery, and special offers!",
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Benefits of becoming premium
  Widget _buildBenefitsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildBenefitItem(Icons.percent, "Flat 15% OFF Everytime",
              "No ifs & buts. 15% OFF means 15% OFF. No max discount cap."),
          _buildBenefitItem(Icons.local_shipping, "ZERO Delivery/Packaging Fees",
              "No Delivery, Packaging, or Surge Charges. Just pay for what you eat."),
          _buildBenefitItem(Icons.star, "Handpicked Brands ONLY",
              "Select from our curated list with the best restaurants."),
        ],
      ),
    );
  }

  // Benefit item widget
  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Button to purchase premium membership
  Widget _buildBuyButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        String userId = _auth.currentUser!.uid;
        await activatePremiumMembership(userId);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => PaymentScreen()
        ));
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Premium Membership Activated!')),
        // );
        // setState(() {
        //   _isPremium = true;
        // });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[800],
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        "Buy Premium Membership",
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}

// Function to activate premium membership
Future<void> activatePremiumMembership(String userId) async {
  await FirebaseFirestore.instance.collection('premium_users').doc(userId).set({
    'uid': userId,
    'premiumStatus': true,
    'premiumStartDate': FieldValue.serverTimestamp(),
    'premiumEndDate': DateTime.now().add(Duration(days: 30)), // 1-month membership
    'benefits': ['Discounts', 'Free Delivery'],
  });

  // Also update the user's document in the 'users' collection
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'isPremium': true,
    'premiumEndDate': DateTime.now().add(Duration(days: 30)), // Set end date for automatic expiration
  });
}

// Function to check if a user is a premium member
Future<bool> isPremiumUser(String userId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  if (snapshot.exists) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return data['isPremium'] == true;
  }
  return false;
}

// Function to automatically set 'isPremium' to false if the premium period has expired
Future<void> checkAndExpirePremiumMembership(String userId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (snapshot.exists) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    DateTime? premiumEndDate = (data['premiumEndDate'] as Timestamp?)?.toDate();

    if (premiumEndDate != null && DateTime.now().isAfter(premiumEndDate)) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isPremium': false,
      });
    }
  }
}
