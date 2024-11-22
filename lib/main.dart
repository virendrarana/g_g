import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_g/screens/add_funds_screen.dart';
import 'package:g_g/screens/admin_screens/admin_dashboard.dart';
import 'package:g_g/screens/cart_screen.dart';
import 'package:g_g/screens/customer_dashboard.dart';
import 'package:g_g/screens/customer_homescreen.dart';
import 'package:g_g/screens/delivery_partner_screens/delivery_dashboard.dart';
import 'package:g_g/screens/login_screen.dart';
import 'package:g_g/screens/order_confirmation_page.dart';
import 'package:g_g/screens/order_history_page.dart';
import 'package:g_g/screens/premium_member_screen.dart';
import 'package:g_g/screens/profile_screen.dart';
import 'package:g_g/screens/promoter_screens/promoter_dashboard_screen.dart';
import 'package:g_g/screens/restaurant_menu_screen.dart';
import 'package:g_g/screens/signup_screen.dart';
import 'package:g_g/screens/splash_screen.dart';
import 'package:g_g/services/cart_service.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => Cart(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => AuthCheck(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/customer_dashboard': (context) => CustomerDashboard(),
        '/admin_dashboard': (context) => AdminDashboard(),
        '/promoter_dashboard': (context) => PromoterDashboardScreen(),
        '/profile': (context) => ProfilePage(),
        '/add_funds': (context) => AddFundsScreen(),
        '/restaurant_menu': (context) => RestaurantMenuPage(restaurantId: ''),
        '/customer_homescreen': (context) => CustomerHomeScreen(),
        '/delivery_dashboard': (context) => DeliveryPartnerDashboardScreen(),
        '/cart': (context) => CartPage(),
        'premium_content': (context) => PremiumMembershipPage(),
        'order_history': (context) => OrderHistoryPage(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          // Fetch user role and navigate to the appropriate dashboard
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                String role = userData['role'];
                String fullName = userData['fullName'] ?? 'Customer'; // Assuming full name is in the users document

                switch (role) {
                  case 'Admin':
                    return AdminDashboard();
                  case 'Customer':
                  // Check if the customer has a wallet
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('wallets')
                          .doc(snapshot.data!.uid)
                          .get(),
                      builder: (context, walletSnapshot) {
                        if (walletSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (walletSnapshot.hasData && !walletSnapshot.data!.exists) {
                          // Wallet does not exist, so create it
                          FirebaseFirestore.instance
                              .collection('wallets')
                              .doc(snapshot.data!.uid)
                              .set({
                            'fullName': fullName,
                            'points': 0,
                            'transactionHistory': [], // Initialize as an empty array
                          });
                        }
                        // Wallet exists or has been created, navigate to Customer dashboard
                        return CustomerHomeScreen();
                      },
                    );
                  case 'Promoter':
                    return PromoterDashboardScreen();
                  case 'DeliveryPartner':
                    return DeliveryPartnerDashboardScreen();
                  default:
                    return Center(child: Text('Error: Unknown user role'));
                }
              } else {
                return Center(child: Text('Error: User data not found'));
              }
            },
          );
        } else {
          // Show login screen if the user is not authenticated
          return LoginScreen();
        }
      },
    );
  }
}
