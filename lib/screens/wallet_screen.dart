import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  int points = 0;
  List<dynamic> transactionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Fetch user's name
        DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          userName = userSnapshot['fullName'] ?? 'User';
        });

        // Fetch wallet data (points and transactions)
        DocumentSnapshot walletSnapshot = await _firestore.collection('wallets').doc(user.uid).get();
        if (walletSnapshot.exists) {
          setState(() {
            points = walletSnapshot['points'] ?? 0;
            transactionHistory = walletSnapshot['transactionHistory'] ?? [];
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: Text(''),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(context),
            SizedBox(height: 20),
            _buildCreditsInfoSection(),
            SizedBox(height: 20),
            _buildRecentTransactionsHeader(),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  // Header with user's name, points balance, and tabs (Credits, T&C, FAQs)
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Hello, ${userName ?? 'User'}",
            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            "Your credit balance is",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            '₹$points',
            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Credits", isSelected: true),
              _buildTabButton("T&C"),
              _buildTabButton("FAQs"),
            ],
          ),
        ],
      ),
    );
  }

  // Tab button for navigation within wallet
  Widget _buildTabButton(String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide(color: isSelected ? Colors.black : Colors.grey),
        ),
        onPressed: () {},
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Section to display information about credits
  Widget _buildCreditsInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Credits work like REAL CASH!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Valid on top of other discounts. No limit on usage whatsoever.",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCreditConversion("1 Credit", "images/rupee_coin_2.png"),
              Text(
                "=",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              _buildCreditConversion("1 Rupee", "images/rupee_symbol.png"),
            ],
          ),
        ],
      ),
    );
  }


  // Helper for credit conversion display
  Widget _buildCreditConversion(String text, String imagePath) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 75, // Set the width and height as needed
          height: 75,
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }


  // Recent Transactions Header
  Widget _buildRecentTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        'Recent Transactions',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Recent Transactions List
  Widget _buildTransactionList() {
    if (transactionHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'No recent transactions.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: transactionHistory.map((transaction) {
        double pointsAdded = (transaction['pointsAdded'] ?? 0).toDouble();

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.0),
            leading: Icon(
              pointsAdded > 0 ? Icons.add_circle : Icons.remove_circle,
              color: pointsAdded > 0 ? Colors.green : Colors.red,
              size: 30,
            ),
            title: Text(
              transaction['description'] ?? 'No description available',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              transaction['timestamp'] != null
                  ? (transaction['timestamp'] as Timestamp).toDate().toLocal().toString()
                  : 'No date available',
            ),
            trailing: Text(
              '${pointsAdded > 0 ? '+' : ''}$pointsAdded',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: pointsAdded > 0 ? Colors.green : Colors.red,
                fontSize: 18,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
