import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_g/screens/contact_us_page.dart';
import 'package:g_g/screens/wallet_screen.dart';
import 'package:g_g/screens/order_history_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: Center(
          child: Text('No user is currently logged in.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User data not found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = userData['fullName'] ?? 'No name provided';
          String email = userData['email'] ?? 'No email provided';
          bool isPremium = userData['premiumStatus'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(fullName, email, isPremium),
                SizedBox(height: 20),
                _buildWalletBalanceCard(),
                SizedBox(height: 20),
                _buildOptionsList(),
                SizedBox(height: 20),
                _buildLogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String fullName, String email, bool isPremium) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.teal[100],
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 50,
                  color: Colors.teal[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isPremium)
              Positioned(
                bottom: 0,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          fullName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10),
        Text(
          email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('wallets').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: Text('Wallet data not found.'),
          );
        }

        var walletData = snapshot.data!.data() as Map<String, dynamic>;
        int points = walletData['points'] ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalletPage(),
              ),
            );
          },
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '$points Points',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsList() {
    return Column(
      children: [
        _buildOptionCard(
          icon: Icons.history,
          title: 'Order History',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryPage()),
            );
          },
        ),
        SizedBox(height: 10),
        _buildOptionCard(
          icon: Icons.lock,
          title: 'Change Password',
          onTap: _showChangePasswordDialog,
        ),
        SizedBox(height: 10),
        _buildOptionCard(
          icon: Icons.contact_mail,
          title: 'Contact Us',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ContactUsPage()),
            );
          },
        ),
        SizedBox(height: 10),
        _buildOptionCard(
          icon: Icons.shopping_bag,
          title: 'Your Orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _showLogoutConfirmationDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        'Logout',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _auth.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPassword = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Change Password'),
          content: TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password',
            ),
            onChanged: (value) {
              newPassword = value;
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change', style: TextStyle(color: Colors.teal)),
              onPressed: () async {
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password must be at least 6 characters long.')),
                  );
                  return;
                }
                try {
                  await user!.updatePassword(newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password updated successfully.')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update password.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
