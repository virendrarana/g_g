import 'package:flutter/material.dart';
import 'package:g_g/screens/admin_screens/admin_subscription_management_page.dart';
import 'package:g_g/screens/admin_screens/id_create_page.dart';
import 'package:g_g/screens/admin_screens/menu_item_management_screen.dart';
import 'package:g_g/screens/admin_screens/restaurants_management_screen.dart';
import 'package:g_g/screens/admin_screens/tracking_screen.dart';
import 'package:g_g/screens/admin_screens/users_management_screen.dart';
import '../settings_screen.dart';
import 'assign_order_screen.dart';
import 'coupons_management_screen.dart';
import 'orders_management_screen.dart';
import 'restaurantSelectionScreen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Override the back button
      onWillPop: () async {
        // Prevent the admin from going back
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard'),
          automaticallyImplyLeading: false, // Disable the back button in the AppBar
          backgroundColor: Colors.teal,
        ),
        body: GridView.count(
          crossAxisCount: 2, // Display 2 cards in each row
          padding: const EdgeInsets.all(16.0),
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildDashboardCard(
              context,
              icon: Icons.people,
              title: 'User Management',
              screen: UsersManagementScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Generate ID',
              screen: GenerateLoginPage(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.restaurant,
              title: 'Restaurant Management',
              screen: RestaurantManagementScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.assignment,
              title: 'Order Assign',
              screen: AssignOrderScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.menu_book,
              title: 'Menu Management',
              screen: RestaurantSelectionScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.shopping_bag,
              title: 'Order Management',
              screen: OrderManagementScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.shopping_bag,
              title: 'Subscription Management',
              screen: AdminSubscriptionTrackingScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.location_on,
              title: 'Tracking Screen',
              screen: AdminTrackingScreen(deliveryPartnerId: ''),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.bar_chart,
              title: 'Reports',
              screen: ReportsScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.local_offer,
              title: 'Coupon Management',
              screen: CouponManagementScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              screen: NotificationsScreen(),
            ),
            _buildDashboardCard(
              context,
              icon: Icons.settings,
              title: 'Settings',
              screen: SettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create a dashboard card for each feature
  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required Widget screen}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.teal),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
