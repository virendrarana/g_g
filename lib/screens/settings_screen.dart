import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_g/screens/profile_screen.dart';
import '../screens/contact_us_screen.dart';


class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false; // Default theme
  bool _notificationsEnabled = true; // Default notification setting

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          _isDarkTheme = userDoc['isDarkTheme'] ?? false;
          _notificationsEnabled = userDoc['notificationsEnabled'] ?? true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load settings: $e")),
      );
    }
  }

  Future<void> _toggleTheme(bool isDarkTheme) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isDarkTheme': isDarkTheme,
      });
      setState(() {
        _isDarkTheme = isDarkTheme;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update theme: $e")),
      );
    }
  }

  Future<void> _toggleNotifications(bool isEnabled) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notificationsEnabled': isEnabled,
      });
      setState(() {
        _notificationsEnabled = isEnabled;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update notification settings: $e")),
      );
    }
  }

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          SwitchListTile(
            title: Text('Dark Theme'),
            value: _isDarkTheme,
            onChanged: _toggleTheme,
          ),
          ListTile(
            title: Text('Change Password'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          ListTile(
            title: Text('Contact Us'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactUsScreen()),
              );
            },
          ),
          Divider(height: 40),
          ListTile(
            title: Text('Log Out'),
            trailing: Icon(Icons.exit_to_app),
            onTap: _logOut,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
