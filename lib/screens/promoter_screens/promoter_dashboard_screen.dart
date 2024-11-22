import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_g/screens/login_screen.dart'; // Assuming you have a login screen to redirect after logout

class PromoterDashboardScreen extends StatefulWidget {
  @override
  _PromoterDashboardScreenState createState() =>
      _PromoterDashboardScreenState();
}

class _PromoterDashboardScreenState extends State<PromoterDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  String _referralCode = '';
  bool _isLoading = false;
  bool _hasReferralCode = false; // Tracks if the promoter already has a referral code
  DocumentSnapshot? _existingReferralCode; // Store existing referral code data

  User? user = FirebaseAuth.instance.currentUser; // Promoter logged in

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _checkForExistingReferralCode();
    }
  }

  // Function to check if the promoter already has a referral code
  Future<void> _checkForExistingReferralCode() async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot referralSnapshot = await FirebaseFirestore.instance
          .collection('referral_codes')
          .where('promoterId', isEqualTo: user!.uid)
          .limit(1)
          .get();

      if (referralSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasReferralCode = true;
          _existingReferralCode = referralSnapshot.docs.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch referral code: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to generate a referral code if one doesn't exist
  Future<void> _generateReferralCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the promoter's name from the user's profile in Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final String promoterName = userDoc['fullName'] ?? 'Unknown'; // Assuming 'fullName' is stored in user's document

      await FirebaseFirestore.instance.collection('referral_codes').add({
        'code': _referralCode,
        'promoterId': user!.uid,
        'promoterName': promoterName,
        'usageCount': 0,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        _hasReferralCode = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral code generated successfully!'),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate referral code: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to track and show referral code usage
  Stream<QuerySnapshot> _fetchReferralCodes() {
    return FirebaseFirestore.instance
        .collection('referral_codes')
        .where('promoterId', isEqualTo: user!.uid)
        .snapshots();
  }

  // Fetch users who signed up using this promoter's referral code
  Stream<QuerySnapshot> _fetchReferredUsers(String referralCode) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('referralCodeUsed', isEqualTo: referralCode)
        .snapshots();
  }

  // Fetch earnings details for the promoter
  Future<int> _fetchPromoterEarnings() async {
    try {
      DocumentSnapshot walletSnapshot = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user!.uid)
          .get();

      if (walletSnapshot.exists) {
        return walletSnapshot['points'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Logout function with confirmation
  Future<void> _logout(BuildContext context) async {
    bool shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Dismiss
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()), // Redirect to login
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promoter Dashboard'),
        backgroundColor: Colors.teal,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context), // Trigger logout confirmation
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.teal.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Referral Code Generation Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Generate Referral Code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      SizedBox(height: 20),

                      // If promoter already has a referral code, disable form and show existing code
                      if (_hasReferralCode && _existingReferralCode != null)
                        Column(
                          children: [
                            Text(
                              'You have already created a referral code.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.teal.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Referral Code: ${_existingReferralCode!['code']}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        )
                      else
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Enter Referral Code',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a referral code';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _referralCode = value!.trim();
                                },
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed:
                                _isLoading ? null : _generateReferralCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : Text(
                                  'Generate Code',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Display Earnings
              FutureBuilder<int>(
                future: _fetchPromoterEarnings(),
                builder: (context, snapshot) {
                  int earnings = snapshot.data ?? 0;
                  return Text(
                    'Total Earnings: ₹$earnings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Display Referral Code and Users Who Signed Up
              if (_hasReferralCode && _existingReferralCode != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users Signed Up with Your Referral Code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _fetchReferredUsers(_existingReferralCode!['code']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No Users Have Signed Up with Your Code Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var userData = snapshot.data!.docs[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 8,
                                  margin: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 5),
                                  child: ListTile(
                                    leading: Icon(Icons.person, color: Colors.teal, size: 30),
                                    title: Text(
                                      'Name: ${userData['fullName']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Email: ${userData['email']}\n'
                                          'Subscription Status: ${userData['hasSubscription'] == true ? 'Subscribed' : 'Not Subscribed'}',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
