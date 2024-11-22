import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:g_g/screens/customer_dashboard.dart';
import 'package:g_g/screens/premium_member_screen.dart';
import 'package:g_g/screens/profile_screen.dart';
import 'package:g_g/screens/wallet_screen.dart';
import 'subscription/subscription_setup_screen.dart';
import 'package:badges/badges.dart' as badges; // Import badges package

class CustomerHomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  bool _isPremium = false;
  bool _isBannerDismissed = false;
  bool _isBannerShownThisSession = false;

  static const Color Tile_color = Color.fromRGBO(250, 248, 246, 1);
  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
  static const Color button_in_color = Color.fromRGBO(193, 212, 192, 1);
  static const Color user_tile_color = Color.fromRGBO(211, 211, 211, 1);



  static List<Widget> _widgetOptions = <Widget>[
    CustomerDashboard(),
    WalletPage(),
    PremiumMembershipPage(),
    SubscriptionSetupScreen(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchPremiumStatus();
  }

  Future<void> _fetchPremiumStatus() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _isPremium = userDoc['isPremium'] ?? false;
          _isBannerDismissed = false;
          _isBannerShownThisSession = false;
        });
      }
    } catch (e) {
      print("Error fetching user premium status: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _widgetOptions.elementAt(_selectedIndex),
          if (!_isPremium && !_isBannerDismissed && !_isBannerShownThisSession)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Please purchase a premium subscription for exclusive benefits.',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isBannerDismissed = true;
                          _isBannerShownThisSession = true;
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PremiumMembershipPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Upgrade Now',
                        style: GoogleFonts.lato(
                          color: Colors.amberAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildWalletIconWithBadge(),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timelapse_sharp),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Subscription',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_sharp),
                label: 'Account',
              ),
            ],
            currentIndex: _selectedIndex == 2 ? 0 : _selectedIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
          ),
          Positioned(
            bottom: 10,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () {
                _onItemTapped(2);
              },
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('images/GUTFUL_GREENS.png'),
                    fit: BoxFit.fill,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletIconWithBadge() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('wallets').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Icon(Icons.wallet);
        }

        final walletData = snapshot.data!.data() as Map<String, dynamic>;
        final int points = walletData['points'] ?? 0;

        return badges.Badge(
          badgeContent: Text(
            '$points',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          badgeColor: button_color,
          child: Icon(Icons.wallet),
        );
      },
    );
  }
}

